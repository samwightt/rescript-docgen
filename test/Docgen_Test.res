open RescriptBun.Test

/**
 We need real rescript modules to test against, so we use RescriptCore. Modules are fairly stable, but the path
 to them may change over time. This function joins the paths as expected.
 */
let getCoreModulePath = (moduleName: string) => {
  RescriptBun.Path.resolve([RescriptBun.Global.dirname, "../node_modules/@rescript/core/src", moduleName])
}

describe("Docgen", () => {
  describe("parseModule", () => {
    testAsync("it should work with RescriptCore modules", async () => {
      let result = await getCoreModulePath("Core__Map.res")->Docgen.parseModule
      let result = Result.getExn(result)
      expect(result.name)->Expect.toEqual("Core__Map")

      let differentResult = await getCoreModulePath("Core__Array.res")->Docgen.parseModule
      let actualResult = differentResult->Result.getExn
      expect(actualResult.name)->Expect.toEqual("Core__Array")
    })
  
    testAsync("it handles the case where the module doesn't exist", async () => {
      let result = await getCoreModulePath("DoesNotExist.res")->Docgen.parseModule

      result
      ->expect
      ->Expect.toEqual(Error(FileDoesNotExist))
    })
  })
})