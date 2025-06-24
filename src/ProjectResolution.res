open RescriptBun

// Node.js fs.Dirent type
type dirent = {
  name: string,
  isDirectory: unit => bool,
}

// readdir with withFileTypes and recursive options. RescriptBun doesn't have the promises version of this yet :/
@module("fs/promises") 
external readdirWithDirents: (string, @as(json`{"withFileTypes": true, "recursive": true}`) _) => promise<array<dirent>> = "readdir"

type getSourceDirsReturn = promise<array<string>>

/**
 Returns all directory paths recursively within the given directory path.
 */
let getAllDirectories = async (directoryPath: string): array<string> => {
  let dirents = await readdirWithDirents(directoryPath)
  
  dirents
  ->Array.filter(dirent => dirent.isDirectory())
  ->Array.map(dirent => Path.resolve([directoryPath, dirent.name]))
}

/**
 Given a Rescript config and a path, returns the list of source directories.
 */
let rec getSourceDirs = (sources: array<RescriptConfig.sourceItem>, path: string): getSourceDirsReturn => {
  let mapSource = (source: RescriptConfig.sourceItem): getSourceDirsReturn => {
    // We need this so that we can pass it to our recursive call.
    let joinedPath = Path.resolve([path, source.dir])

    // Confusing part 1: subdirsPromise is a PROMISE. That's because getSourceDirs accepts an ARRAY.
    // I thought it would need to be an array of promises, but it's a SINGLE promise. So we need to Promise.resolve([])
    // our empty array here.
    let subdirsPromise = switch source.subdirs {
    | NoSubdirs => Promise.resolve([])
    | SubdirList(list) => getSourceDirs(list, joinedPath)
    | TraverseAll => getAllDirectories(joinedPath)
    }

    // Wait for the subdirs promise to resolve, then append this path onto that result when that happens.
    subdirsPromise
    ->Promise.thenResolve(Array.concat(_, [joinedPath]))
  }

  sources
  ->Array.map(mapSource)
  ->Promise.all
  // We need one last Array.flat on top of this, because `Promise.all` will return a two-dimensional array. ugh.
  ->Promise.thenResolve(Array.flat)
}