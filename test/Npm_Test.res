open RescriptBun.Test

describe("Npm", () => {
  describe("fetchPackageDetails", () => {
    testAsync("successfully fetches package details from npm", async () => {
      let result = await Npm.fetchPackageDetails("rescript")

      result
      ->expect
      ->Expect.toBeTruthy

      let result = Result.getExn(result)
      expect(result.name)->Expect.toEqual("rescript")
      result.versions
      ->Dict.getUnsafe("11.0.0")
      ->(x => x.Npm.dist.tarball)
      ->expect
      ->Expect.toEqual("https://registry.npmjs.org/rescript/-/rescript-11.0.0.tgz")
    })

    testAsync("it handles cases where the npm module doesn't exist", async () => {
      let result = await Npm.fetchPackageDetails("4829104859_58393-$#@@")
      expect(result)->Expect.toEqual(Error("Not found"))
    })
  })

  describe("getLatestVersion", () => {
    testAsync("it returns the latest version", async () => {
      let details = await Npm.fetchPackageDetails("rescript")->Promise.thenResolve(Result.getExn)
      details
      ->Npm.getLatestVersion
      ->expect
      ->Expect.toBeTruthy
    })
  })
})