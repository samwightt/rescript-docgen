open RescriptBun.Test

describe("RescriptConfig", () => {
  describe("configFromJsonString", () => {
    test(
      "parses simple JSON string",
      () => {
        `{ "name": "asdf project", "sources": "./src" }`
        ->RescriptConfig.configFromJsonString
        ->expect
        ->Expect.toEqual({
          name: "asdf project",
          dependencies: [],
          devDependencies: [],
          pinnedDependencies: [],
          sources: [
            {
              dir: "./src",
              isDev: false,
              subdirs: NoSubdirs,
            },
          ],
        })
      },
    )

    describe(
      "dependencies",
      () => {
        test(
          "works with dependencies",
          () => {
            let parsed =
              `{ "name": "another project", "sources": "./src", "bs-dependencies": ["rescript-bun"] }`->RescriptConfig.configFromJsonString
            parsed.dependencies
            ->expect
            ->Expect.toEqual(["rescript-bun"])
          },
        )

        test(
          "works with dev deps",
          () => {
            let parsed =
              `{ "name": "another project", "sources": "./src", "bs-dev-dependencies": ["rescript-bun"] }`->RescriptConfig.configFromJsonString
            parsed.devDependencies
            ->expect
            ->Expect.toEqual(["rescript-bun"])
          },
        )

        test(
          "works with pinned deps",
          () => {
            let parsed =
              `{ "name": "another project", "sources": "./src", "pinned-dependencies": ["rescript-bun"] }`->RescriptConfig.configFromJsonString

            parsed.pinnedDependencies
            ->expect
            ->Expect.toEqual(["rescript-bun"])
          },
        )

        test(
          "works with all types of deps at same time",
          () => {
            `{ "name": "another project", "sources": "./src", "bs-dependencies": ["rescript-bun"], "bs-dev-dependencies": ["rescript-bun"], "pinned-dependencies": ["rescript-bun"] }`
            ->RescriptConfig.configFromJsonString
            ->expect
            ->Expect.toEqual({
              name: "another project",
              dependencies: ["rescript-bun"],
              devDependencies: ["rescript-bun"],
              pinnedDependencies: ["rescript-bun"],
              sources: [
                {
                  dir: "./src",
                  isDev: false,
                  subdirs: NoSubdirs,
                },
              ],
            })
          },
        )
      },
    )

    describe(
      "sources",
      () => {
        let getSources = (config: RescriptConfig.t) => {
          config.sources
        }

        test(
          "works with basic object source",
          () => {
            `{ "name": "another project", "sources": [{ "dir": "./src" }] }`
            ->RescriptConfig.configFromJsonString
            ->getSources
            ->expect
            ->Expect.toEqual([
              {
                dir: "./src",
                isDev: false,
                subdirs: NoSubdirs,
              },
            ])
          },
        )

        test(
          "subdirs defaults to NoSubdirs",
          () => {
            `{ "name": "another project", "sources": [{ "dir": "./src" }] }`
            ->RescriptConfig.configFromJsonString
            ->getSources
            ->expect
            ->Expect.toEqual([
              {
                dir: "./src",
                isDev: false,
                subdirs: NoSubdirs,
              },
            ])
          },
        )

        test(
          "subdirs: true is TraverseAll",
          () => {
            `{ "name": "another project", "sources": [{ "dir": "./src", "subdirs": true }] }`
            ->RescriptConfig.configFromJsonString
            ->getSources
            ->expect
            ->Expect.toEqual([
              {
                dir: "./src",
                isDev: false,
                subdirs: TraverseAll,
              },
            ])
          },
        )

        test(
          "works with object source",
          () => {
            `{ "name": "another project", "sources": [{ "dir": "./src", "type": "dev" }] }`
            ->RescriptConfig.configFromJsonString
            ->getSources
            ->expect
            ->Expect.toEqual([
              {
                dir: "./src",
                isDev: true,
                subdirs: NoSubdirs,
              },
            ])
          },
        )

        test(
          "works with array of string sources",
          () => {
            `{ "name": "another project", "sources": ["./src", "./example"] }`
            ->RescriptConfig.configFromJsonString
            ->getSources
            ->expect
            ->Expect.toEqual([
              {dir: "./src", isDev: false, subdirs: NoSubdirs},
              {
                dir: "./example",
                isDev: false,
                subdirs: NoSubdirs,
              },
            ])
          },
        )

        test(
          "works with mixed array of string and object sources",
          () => {
            `{ "name": "another project", "sources": ["./src", { "dir": "./example" }] }`
            ->RescriptConfig.configFromJsonString
            ->getSources
            ->expect
            ->Expect.toEqual([
              {
                dir: "./src",
                isDev: false,
                subdirs: NoSubdirs,
              },
              {
                dir: "./example",
                isDev: false,
                subdirs: NoSubdirs,
              },
            ])
          },
        )

        test(
          "isDev is set to true if type is dev",
          () => {
            `{ "name": "another project", "sources": [{ "dir": "./src", "type": "dev" }] }`
            ->RescriptConfig.configFromJsonString
            ->getSources
            ->expect
            ->Expect.toEqual([
              {
                dir: "./src",
                isDev: true,
                subdirs: NoSubdirs,
              },
            ])
          },
        )
      },
    )
  })
})
