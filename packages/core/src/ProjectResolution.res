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

/**
 Given a project's source list, returns a list of all modules in that project.
 Returns a list of absolute paths to those modules.
 */
let projectModules = async (sources: array<RescriptConfig.sourceItem>, path: string): array<string> => {
  let projectDirectories = await getSourceDirs(sources, path)

  let glob = Bun.Glob.make("*.res")

  // Glob uses async iterator so unfortunately we have to async iterator forEach and iteratively PUSH TO THE ARRAY
  // LIKE WE'RE NEANDERTHALS. UGH.

  let pathArr = []

  let scan = async (dir: string): unit => {
    await glob->Bun.Glob.scan(~options = {
      // Rescript implement Rust Default trait challenge: impossible edition
      cwd: dir,
      absolute: true,
      onlyFiles: true,
      dot: false,
      throwErrorOnBrokenSymlink: false,
      followSymlinks: false
    // Why we don't have more methods for async iterator is beyond me.
    })->AsyncIterator.forEach(item => {
      switch item {
      | Some(path) => Array.push(pathArr, path)
      | None => ()
      }
    })
  }

  // Run concurrently and wait for them all to finish. Then we can return.
  (await projectDirectories->Array.map(scan)->Promise.all)->ignore

  pathArr
}

let pathToModuleName = (path: string) => {
  path
  ->RescriptBun.Path.basenameExt(".res")
}

let findProjectConfig = async (path: string): result<RescriptConfig.t, string> => {
  let file = Path.resolve([path, "rescript.json"])->Bun.file
  let exists = await Bun.BunFile.exists(file)
  if !exists {
    Error("No rescript.json file found")
  } else {
    await file->Bun.BunFile.text->Promise.thenResolve(RescriptConfig.configFromJsonString)
  }
}