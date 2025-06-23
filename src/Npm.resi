/**
 This is where the tarball URLs come from in npm.
 */
type dist = {
  tarball: string
}

/**
 An individual version in the JSON returned from the npm registry.
 Has keywords and `dist`, which contains an optional tarball URL.
 */
type version = {
  id: option<string>,
  keywords: option<array<string>>,
  dist
}

/**
 For our purposes we only need the 'latest' tag, but it might not necessarily be set.
 So just use an option for it for now.
 */
type distTags = {
  latest: option<string>
}

/**
 The package details returned from the npm registroy. `name` is the name of the package,
 `versions` is a dict of all the versions of the package. Keywords is optional tags. distTags
 are the 'tags' of the package, such as 'latest' or 'next'.
 */
type packageDetails = {
  versions: Dict.t<version>,
  distTags,
  keywords: option<array<string>>,
  name: string
}


/**
 Fetches package details from the npm registry.

 To get the tarball of a package, you need the version. If you don't know a version, use the distTags.latest
 tag to get the latest version tag. Then get the tarball from the dist object on the version.
 */
let fetchPackageDetails: (string) => promise<result<packageDetails, string>>
/**
 Gets the latest version of a package through the distTags.
 */
let getLatestVersion: (packageDetails) => option<version>
/**
 Given a version, gets the tarballUrl off of it.
 */
let tarballUrl: (version) => string
/**
 Gets the tarball url of a version string from the package details.
 */
let versionTarballUrl: (packageDetails, string) => option<string>