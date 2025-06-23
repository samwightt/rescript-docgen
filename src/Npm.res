type dist = {
  tarball: string
}

type version = {
  id: option<string>,
  keywords: option<array<string>>,
  dist
}
type distTags = {
  latest: option<string>
}

type packageDetails = {
  versions: Dict.t<version>,
  distTags,
  keywords: option<array<string>>,
  name: string
}

let version = S.object(s => {
  id: s.field("id", S.option(S.string)),
  keywords: s.field("keywords", S.option(S.array(S.string))),
  dist: s.field("dist", S.object(s => {
    tarball: s.field("tarball", S.string)
  }))
})

/**
 Package details can either be an object with the package details, or an object with the 'error' key with
 an error message.
 */
let packageDetails = 
  S.union([
    S.object(s => {
      Error(s.field("error", S.string))
    }),
    S.object(s => Ok({
      versions: s.field("versions", S.dict(version)),
      distTags: s.field("dist-tags", S.object(s => {
        latest: s.field("latest", S.option(S.string))
      })),
      keywords: s.field("keywords", S.option(S.array(S.string))),
      name: s.field("name", S.string)
    }))
  ])

let fetchPackageDetails = async (packageName) => {
  let result = decodeURI(packageName)
  let url = `https://registry.npmjs.org/${result}`
  let result = await RescriptBun.Globals.fetch(url)->Promise.then(RescriptBun.Globals.Response.json)
  result->S.parseJsonOrThrow(packageDetails)
}

let getLatestVersion = (packageDetails) => {
  packageDetails.distTags.latest
  ->Option.flatMap(Dict.get(packageDetails.versions, _))
}

let tarballUrl = (version) => {
  version.dist.tarball
}

let versionTarballUrl = (packageDetails, version) => {
  version
  ->Dict.get(packageDetails.versions, _)
  ->Option.map(tarballUrl)
}