open RescriptBun.Test

describe("RescriptConfig", () => {
  describe("configFromJsonString", () => {
    test(
      "parses simple JSON string",
      () => {
        `{ "name": "asdf project", "sources": "./src" }`
        ->RescriptConfig.configFromJsonString
        ->Result.getExn
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
              `{ "name": "another project", "sources": "./src", "bs-dependencies": ["rescript-bun"] }`
              ->RescriptConfig.configFromJsonString
              ->Result.getExn
            parsed.dependencies
            ->expect
            ->Expect.toEqual(["rescript-bun"])
          },
        )

        test(
          "works with dev deps",
          () => {
            let parsed =
              `{ "name": "another project", "sources": "./src", "bs-dev-dependencies": ["rescript-bun"] }`
              ->RescriptConfig.configFromJsonString
              ->Result.getExn
            parsed.devDependencies
            ->expect
            ->Expect.toEqual(["rescript-bun"])
          },
        )

        test(
          "works with pinned deps",
          () => {
            let parsed =
              `{ "name": "another project", "sources": "./src", "pinned-dependencies": ["rescript-bun"] }`
              ->RescriptConfig.configFromJsonString
              ->Result.getExn

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
            ->Result.getExn
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
            ->Result.getExn
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
            ->Result.getExn
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
            ->Result.getExn
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
            ->Result.getExn
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
            ->Result.getExn
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
            ->Result.getExn
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
            ->Result.getExn
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
          "works with subdirs as SubdirList",
          () => {
            `{ "name": "another project", "sources": [{ "dir": "./src", "subdirs": ["./nested", { "dir": "./nested2" }] }] }`
            ->RescriptConfig.configFromJsonString
            ->Result.getExn
            ->getSources
            ->expect
            ->Expect.toEqual([
              {
                dir: "./src",
                isDev: false,
                subdirs: SubdirList([
                  {
                    dir: "./nested",
                    isDev: false,
                    subdirs: NoSubdirs,
                  },
                  {
                    dir: "./nested2",
                    isDev: false,
                    subdirs: NoSubdirs,
                  },
                ]),
              },
            ])
          },
        )

        test(
          "works with deeply nested subdirs",
          () => {
            `{ "name": "another project", "sources": [{ "dir": "./src", "subdirs": [{ "dir": "./nested", "subdirs": ["./deeply-nested"] }] }] }`
            ->RescriptConfig.configFromJsonString
            ->Result.getExn
            ->getSources
            ->expect
            ->Expect.toEqual([
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
            ])
          },
        )
      },
    )

    describe(
      "error cases",
      () => {
        test(
          "when name field is missing",
          () => {
            `{ "sources": "./src" }`
            ->RescriptConfig.configFromJsonString
            ->expect
            ->Expect.toEqual(
              Error("Failed parsing at [\"name\"]: Expected string, received undefined"),
            )
          },
        )
      },
    )
  })

  describe("configFromJson", () => {
    test(
      "parses JSON object",
      () => {
        let json = %raw(`{ "name": "test project", "sources": "./src" }`)
        json
        ->RescriptConfig.configFromJson
        ->Result.getExn
        ->expect
        ->Expect.toEqual({
          name: "test project",
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

    test(
      "returns error for invalid JSON object",
      () => {
        let json = %raw(`{ "sources": "./src" }`) // missing required "name" field
        json
        ->RescriptConfig.configFromJson
        ->expect
        ->Expect.toEqual(Error("Failed parsing at [\"name\"]: Expected string, received undefined"))
      },
    )
  })
})
