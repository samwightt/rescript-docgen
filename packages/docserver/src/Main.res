let port = 4444

let unwrapResultPromise = (result: result<promise<'a>, 'b>): promise<result<'a, 'b>> => {
  let result = switch result {
  | Ok(ok) => Ok(ok)
  | Error(error) => Error(error)
  }
  switch result {
  | Ok(promise) => promise->Promise.thenResolve(x => Ok(x))
  | Error(err) => {
    let newErr: result<'a, 'b> = Error(err)
    Promise.resolve(newErr)
  }
  }
}

let currentProjectDetails = async () => {
  let currentDirectory = Process.process->Process.cwd;
  let currentConfig = await DocgenCore.ProjectResolution.findProjectConfig(currentDirectory)

  await currentConfig
    ->Result.map(config => {
      DocgenCore.ProjectResolution.projectModules(config.sources, currentDirectory)
    })
    ->unwrapResultPromise
    ->Promise.thenResolve(Result.map(_, moduleList => {
      moduleList
      ->Array.map(modulePath => {
        "path": modulePath,
        "name": DocgenCore.ProjectResolution.pathToModuleName(modulePath)
      })
    }))
}

let server = Bun.serve({
  port,
  development: ResX.BunUtils.isDev,
  fetch: async (request, server) => {
    switch await ResX.BunUtils.serveStaticFile(request) {
    | Some(staticResponse) => staticResponse
    | None =>
      await Handler.handler->ResX.Handlers.handleRequest({
        request,
        setupHeaders: () => {
          Headers.make(~init=FromArray([("Content-Type", "text/html")]))
        },
        render: async ({ path, requestController, headers}) => {
          switch path {
          // | list{"sitemap.xml"} => <SiteMap />
          | appRoutes =>
            requestController->ResX.RequestController.appendTitleSegment("Test App")

            let deets = switch await currentProjectDetails() {
            | Ok(deets) => <>
                {Array.map(deets, (mod) => {
                  <div>
                    {Hjsx.string(mod["name"])}
                  </div>
                })->Hjsx.array}
              </>
            | Error(error) => <>
                {Hjsx.string(error)}
              </>
            }

            <Layout.Html>
              <div>
                {Hjsx.string("Start page!")}
                deets
              </div>
            </Layout.Html>
          }
        }
      })
    }
  }
})

let portString = server->Bun.Server.port->Int.toString

Console.log(`Listening on localhost:${portString}`)

if ResX.BunUtils.isDev {
  ResX.BunUtils.runDevServer(~port)
}