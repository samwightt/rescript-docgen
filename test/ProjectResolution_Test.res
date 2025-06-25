open RescriptBun.Test

let orderIndependentEqual = (arr, shouldEqual) => {
  arr
  ->expect
  ->Expect.toHaveLength(shouldEqual->Array.length->Int.toFloat)

  shouldEqual->Array.forEach(item => {
    arr
    ->expect
    ->Expect.toContain(item)
  })
}

describe("ProjectResolution", () => {
  describe("getSourceDirs", () => {
    let pathsToSources = x =>
      x->Array.map(
        (path): RescriptConfig.sourceItem => {dir: path, isDev: false, subdirs: NoSubdirs},
      )

    testAsync(
      "concats source dirs with path",
      async () => {
        let basePath = "/foo/bar"

        let res =
          await ["./src", "./test"]
          ->pathsToSources
          ->ProjectResolution.getSourceDirs(basePath)

        orderIndependentEqual(res, ["/foo/bar/src", "/foo/bar/test"])
      },
    )

    testAsync(
      "handles empty sources",
      async () => {
        let basePath = "/foo/bar"

        let res =
          await []
          ->pathsToSources
          ->ProjectResolution.getSourceDirs(basePath)

        orderIndependentEqual(res, [])
      },
    )

    testAsync(
      "handles static subdir lists",
      async () => {
        let basePath = "/foo/bar"
        let res = await ProjectResolution.getSourceDirs(
          [
            {
              dir: "./src",
              isDev: false,
              subdirs: SubdirList([
                {
                  dir: "./nested",
                  isDev: false,
                  subdirs: SubdirList([
                    {
                      dir: "./deeply-nested",
                      isDev: false,
                      subdirs: NoSubdirs,
                    },
                  ]),
                },
              ]),
            },
          ],
          basePath,
        )

        orderIndependentEqual(
          res,
          ["/foo/bar/src", "/foo/bar/src/nested", "/foo/bar/src/nested/deeply-nested"],
        )
      },
    )

    testAsync(
      "handles TraverseAll subdirs",
      async () => {
        let basePath = RescriptBun.Global.dirname
        let root = RescriptBun.Path.resolve([RescriptBun.Global.dirname, "../"])
        let res = await ProjectResolution.getSourceDirs(
          [
            {
              dir: "./node_modules/sury",
              isDev: false,
              subdirs: TraverseAll,
            },
          ],
          root,
        )

        let expectedDirs =
          [
            "node_modules/sury",
            "node_modules/sury/src",
            "node_modules/sury/lib",
            "node_modules/sury/ocaml",
            "node_modules/sury/bs",
            "node_modules/sury/src",
          ]->Array.map(x => RescriptBun.Path.resolve([root, x]))

        orderIndependentEqual(res, expectedDirs)
      },
    )
  })

  describe("projectModules", () => {
    let projectRoot = RescriptBun.Path.resolve([RescriptBun.Global.dirname, "../"])

    // TODO: Make this so you don't have to update the expectedModules array any time a new module is updated lmao.
    testAsync(
      "it works as expected",
      async () => {
        let fakeSources = await ProjectResolution.projectModules(
          [
            {
              dir: "src",
              isDev: false,
              subdirs: NoSubdirs,
            },
          ],
          projectRoot,
        )

        let expectedModules = [
          "src/ProjectResolution.res",
          "src/RescriptConfig.res",
          "src/Main.res",
          "src/Docgen.res"
        ]->Array.map(x => RescriptBun.Path.resolve([projectRoot, x]))

        orderIndependentEqual(fakeSources, expectedModules)
      },
    )
  })

  describe("pathToModule", () => {
    test("works", () => {
      "/hi/hello/Path.res"
      ->ProjectResolution.pathToModuleName
      ->expect
      ->Expect.toEqual("Path")
    })
  })
})
