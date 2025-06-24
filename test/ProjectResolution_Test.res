open RescriptBun.Test

describe("ProjectResolution", () => {
  describe("getSourceDirs", () => {
    let pathsToSources = x =>
      x->Array.map(
        (path): RescriptConfig.sourceItem => {dir: path, isDev: false, subdirs: NoSubdirs},
      )

    let orderIndependentEqual = (arr, shouldEqual) => {
      arr
      ->expect
      ->Expect.toHaveLength(shouldEqual->Array.length->Int.toFloat)

      shouldEqual->Array.forEach(
        item => {
          arr
          ->expect
          ->Expect.toContain(item)
        },
      )
    }

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
        let root = RescriptBun.Path.resolve([basePath, "../"])
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
})
