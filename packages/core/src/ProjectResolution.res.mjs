// Generated by ReScript, PLEASE EDIT WITH CARE

import * as $$Bun from "bun";
import * as Nodepath from "node:path";
import * as Promises from "fs/promises";
import * as Core__AsyncIterator from "@rescript/core/src/Core__AsyncIterator.res.mjs";
import * as RescriptConfig$DocgenCore from "./RescriptConfig.res.mjs";

async function getAllDirectories(directoryPath) {
  var dirents = await Promises.readdir(directoryPath, {"withFileTypes": true, "recursive": true});
  return dirents.filter(function (dirent) {
                return dirent.isDirectory();
              }).map(function (dirent) {
              return Nodepath.resolve(directoryPath, dirent.name);
            });
}

function getSourceDirs(sources, path) {
  var mapSource = function (source) {
    var joinedPath = Nodepath.resolve(path, source.dir);
    var list = source.subdirs;
    var subdirsPromise;
    subdirsPromise = typeof list !== "object" ? (
        list === "TraverseAll" ? getAllDirectories(joinedPath) : Promise.resolve([])
      ) : getSourceDirs(list._0, joinedPath);
    return subdirsPromise.then(function (__x) {
                return __x.concat([joinedPath]);
              });
  };
  return Promise.all(sources.map(mapSource)).then(function (prim) {
              return prim.flat();
            });
}

async function projectModules(sources, path) {
  var projectDirectories = await getSourceDirs(sources, path);
  var glob = new $$Bun.Glob("*.res");
  var pathArr = [];
  var scan = async function (dir) {
    return await Core__AsyncIterator.forEach(glob.scan({
                    cwd: dir,
                    dot: false,
                    absolute: true,
                    followSymlinks: false,
                    throwErrorOnBrokenSymlink: false,
                    onlyFiles: true
                  }), (function (item) {
                  if (item !== undefined) {
                    pathArr.push(item);
                    return ;
                  }
                  
                }));
  };
  await Promise.all(projectDirectories.map(scan));
  return pathArr;
}

function pathToModuleName(path) {
  return Nodepath.basename(path, ".res");
}

async function findProjectConfig(path) {
  var file = Bun.file(Nodepath.resolve(path, "rescript.json"));
  var exists = await file.exists();
  if (exists) {
    return await file.text().then(RescriptConfig$DocgenCore.configFromJsonString);
  } else {
    return {
            TAG: "Error",
            _0: "No rescript.json file found"
          };
  }
}

export {
  getAllDirectories ,
  getSourceDirs ,
  projectModules ,
  pathToModuleName ,
  findProjectConfig ,
}
/* bun Not a pure module */
