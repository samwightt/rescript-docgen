/***
 Does rescript config.
 */

/**
 Subdirs are defined recursively. As in, a sourceItem can have a `subdirs` field that's an array of source items. And so on.
 To do that, we need a recursive type, hence this.
 */
type rec subdirs = TraverseAll | NoSubdirs | SubdirList(array<sourceItem>)
and sourceItem = {
  dir: string,
  isDev: bool,
  subdirs: subdirs,
}

type t = {
  name: string,
  sources: array<sourceItem>,
  dependencies: array<string>,
  devDependencies: array<string>,
  pinnedDependencies: array<string>,
}

/**
 The `type` field is either a constant string (`dev`) or nothing. So instead of using `S.string`,
 we map it to be a boolean and convert it back to a string when serializing.
 */
let isDev =
  S.option(S.literal("dev"))
  ->S.transform(_ => {
    parser: string =>
      switch string {
      | Some("dev") => true
      | _ => false
      },
    serializer: bool =>
      if bool {
        Some("dev")
      } else {
        None
      },
  })
  ->S.meta({
    description: "True if the source is a dev dependency, false if it is not.",
  })

/**
 Subdirs are defined recursively. As in, a sourceItem can have a `subdirs` field that's an array of source items. And so on.
 So in order to do that, this needs to be a function and we need to use `S.recursive` to define it. That allows us to create
 a recursive type fairly easily.
 */
let subdirs = sourcesRef =>
  S.union([
    S.option(S.bool)->S.transform(_ => {
      parser: bool =>
        switch bool {
        | Some(true) => TraverseAll
        | _ => NoSubdirs
        },
      serializer: val =>
        switch val {
        | TraverseAll => Some(true)
        | _ => None
        },
    }),
    sourcesRef->S.transform(s => {
      parser: val => SubdirList(val),
      serializer: val => {
        switch val {
        | SubdirList(x) => x
        | _ => s.fail("Should not happen!")
        }
      },
    }),
  ])

/**
 Basic source item parser (note that it takes sourcesRef due to subdirs).
 */
let sourceItem = sourcesRef =>
  S.object(s => {
    dir: s.field("dir", S.string->S.meta({description: "Name of the directory"})),
    isDev: s.field("type", isDev),
    subdirs: s.field("subdirs", subdirs(sourcesRef)),
  })

/**
 A source config is either a sourceItem object or a string. If it's a string, it's a directory with isDev being false, and subdirs being NoSubdirs.
 Instead of using a union, we just use the single `sourceItem` type.
 */
let sourceConfig = sourcesRef =>
  S.union([
    sourceItem(sourcesRef),
    S.string->S.transform(s => {
      parser: val => {
        dir: val,
        isDev: false,
        subdirs: NoSubdirs,
      },
      serializer: val =>
        switch val {
        | {dir, isDev: false, subdirs: NoSubdirs} => dir
        | _ => s.fail("Should not happen!")
        },
    }),
  ])

/**
 Wraps a schema value in an array, allowing it to be `S.union`-ed with an array.

 Example:

 `S.string->wrapInArray` will match `"asdf"`, but when parsed will be `["asdf"]`.
 When serialized, `["asdf"]` will be serialized to `"asdf"`.

 Throws an error if the value is an array with more than one element.
 */
let wrapInArray = schema => {
  schema->S.transform(s => {
    parser: val => [val],
    serializer: val =>
      switch val {
      | [singleValue] => singleValue
      | _ => s.fail("Can't convert back to array when array has more than one element.")
      },
  })
}

/**
 Final sources type. A source is either an array of sourceConfigs or a single sourceConfig. A sourceConfig
 is either a string or a sourceItem object. 

 We have to use `S.recursive` here to define a recursive type because `sourceItem` is a recurisve type on `sources`.
 */
let sources = S.recursive(sourcesRef =>
  S.union([sourceConfig(sourcesRef)->wrapInArray, S.array(sourceConfig(sourcesRef))])->S.meta({
    description: "An array of source items.",
  })
)

/**
 Shorthand for `S.option(S.array(schema))->S.Option.getOrWith(() => [])`.
 */
let optionalArray = schema => {
  S.option(S.array(schema))->S.Option.getOrWith(() => [])
}

let configSpec = S.object(s => {
  name: s.field("name", S.string),
  sources: s.field("sources", sources),
  dependencies: s.field(
    "bs-dependencies",
    optionalArray(S.string)->S.meta({
      description: "Rescript dependencies of the library, like in package.json. Currently searches in node_modules.",
    }),
  ),
  devDependencies: s.field(
    "bs-dev-dependencies",
    optionalArray(S.string)->S.meta({
      description: "Rescript dev dependencies of the library, like in package.json. Currently searches in node_modules.",
    }),
  ),
  pinnedDependencies: s.field(
    "pinned-dependencies",
    optionalArray(S.string)->S.meta({description: "Dependencies that are pinned (see docs)."}),
  ),
})

/**
 Parses the JSON string and returns a result.
 */
let configFromJsonString = (jsonString: string): result<t, string> => {
  try {
    Ok(S.parseJsonStringOrThrow(jsonString, configSpec))
  } catch {
  | S.Error(error) => Error(error.message)
  }
}

/**
 Parses the JSON object and returns a result.
 */
let configFromJson = (json: JSON.t): result<t, string> => {
  try {
    Ok(S.parseJsonOrThrow(json, configSpec))
  } catch {
  | S.Error(error) => Error(error.message)
  }
}
