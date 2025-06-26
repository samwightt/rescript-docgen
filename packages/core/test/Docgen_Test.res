open RescriptBun.Test

/**
 We use our test-project example modules for testing docgen functionality.
 */
let getExampleModulePath = (moduleName: string) => {
  RescriptBun.Path.resolve([RescriptBun.Global.dirname, "../../../examples/test-project/src", moduleName])
}

describe("Docgen", () => {
  describe("parseModule", () => {
    testAsync("it should work with example modules", async () => {
      let result = await getExampleModulePath("MathUtils.res")->Docgen.parseModule
      let result = Result.getExn(result)
      expect(result.name)->Expect.toEqual("MathUtils")

      let differentResult = await getExampleModulePath("StringHelpers.res")->Docgen.parseModule
      let actualResult = differentResult->Result.getExn
      expect(actualResult.name)->Expect.toEqual("StringHelpers")
    })
  
    testAsync("it handles the case where the module doesn't exist", async () => {
      let result = await getExampleModulePath("DoesNotExist.res")->Docgen.parseModule

      result
      ->expect
      ->Expect.toEqual(Error(FileDoesNotExist))
    })
  })
})