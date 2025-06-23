# rescript-docgen

About a year ago (2024) I wrote an initial version of an on-demand doc generator for Rescript. Essentially docs.rs,
but for any Rescript package, and completely online. ie. you could visit a URL, it would fetch the package, generate the docs,
and show it to you.

For whatever reason I decided to get super smart and add a bunch of confusing functions
like `Utils.promisifyAndFlatten` or `Utils.pAndThen` with absolutely no doc comments and very few tests. When I ran it,
it didn't work for some reason, and no amount of debugging led to a fix lol. For these reasons that code will never ever
see the light of day.

So this is a rewrite focused on:

- Writing idiomatic code
- Not reinventing the standard library (fuck you, past me)
- Testing _everything_.
- Documenting _everything_.

We want to build an experience similar to docs.rs where a user can search for a package on NPM, click on it,
and view the generated Rescript docs for it. Ideally this should happen without package authors having to do anything.
Because the Rescript compiler is incredibly fast, it would be ideal if all of this happened _on demand_ as well,
only downloading and compiling packages when needed.

To do all of this, we need a package that can download packages from NPM, compile them with Rescript, and
get documentation info from them. It should do this safely (without executing arbitrary code), fast (as parallel as possible),
and lazily (reuse previous compilation output if possible).

## High level overview and explanation

In this package, we want a simple function where a user can give a NPM package, a version, and a module inside that package,
and the function returns the documentation JSON for that package. Something like:

```res
 let fetchDocs = async (package: string, version: string, moduleName: string): result<RescriptTools.Docgen.doc, parseError> => {}
```

This function should take care of downloading the package if necessary, downloading its dependencies, compiling it, and running 
the docgen tool on it.

### How Rescript doc generation works

Rescript has a library called `@rescript/tools` for introspecting Rescript code for doc generation.
The doc command is something like:

```sh
rescript-tools doc path/to/res/file
```

In order to run this command, the project must be fully compiled. This allows `@rescript/tools` to get the
types of specific members correctly and also know which members of a module are public. (This would be hard or
impossible to do with simple AST-based analysis. Types cannot be found from analyzing the AST due to Rescript's
strong type inference capabilities. Because Rescript interface files exist (`.resi), you can't tell whether a function
is public or private based on analyzing a single file alone.)

Rescript projects are compiled using the `rescript build` command. It checks the project's `rescript.json` and first compiles
all projects in the `bs-dependencies` array. Dependencies are regular npm packages, and lookup happens by looking through
the `node_modules` folder.

It's important to note that we only need a project's _Rescript dependencies_. eg. if a package has a `vitest` dev dependency or depends on
`react`, we don't need those installed in order to compile the Rescript project.

### Downloading packages from npm

In order to do anything with a package, we first need a package's version. This can be gotten using the public NPM registry API.
See `Npm.res` for more details. Basically there's an endpoint that returns a JSON file for each package, describing all of its versions,
their tarball URLs (for download), and any other details.

Before downloading a package, we want to know whether it is a Rescript package or not (we shouldn't do docgen for `react`). A package
is a Rescript package if it has a `rescript.json` in it. We can use [unpkg](https://unpkg.com/) to tell whether a package has a `rescript.json`
without downloading and unpacking it (slower). We can also use this to resolve a project's dependencies...?

After we've fetched a package's info, we have a tarball URL that we can use to download and install the package. My original version worked
by doing this manually but didn't account for a package's dependencies (complicated lol).

Note: overthinking follows. I think just using `bun install` and doing that without running any scripts I guess.

I'm not sure on how to resolve the project's dependencies. If we do `npm install` or `bun install`, a bunch of unnecessary packages are installed,
and it risks having scripts run during install that could compromise the system. It also removes the ability to optimize installation: once we have a
dependency installed _and compiled_, we never have to compile it again (npm versions do not change). This means that we could have a single cache directory
with a folder structure like `cache/<package name>/<version>/<untarballed contents>`, and just symlink the contents where they're needed. However, this
requires basically duplicating a lot of `npm`'s package resolution techniques because not all packages publish a `package-lock.json`
(eg. the current version of [`@rescript/core` does not](https://app.unpkg.com/@rescript/core@1.6.1)), so we'd either have to use something like the arborist API
(forget what it's called) or do something different to get the versions of the package that we need to install.

Hmm now that I think about it, it's probably easier to just use `bun install` or something. Peer deps wouldn't be handled by the above and I have no idea on how
to do that well. And versions can change as newer packages get published, so we might have to re-link or recompile things if a patch version of one of our dependencies
gets published for instance. Hmmmmmmmmmmmm

Once dependencies are resolved, a project can be safely downloaded via the tarball found earlier and untarballed to a dir. 

#### Problems with the overthinking approach

- Each project has different Rescript versions, Rescript is typically installed as a dev dependency. Don't want to have to write out all that logic.
- Peer deps aren't handled
- When new package updates are pushed (eg. patch deps) our project probably needs to be rebuilt with the updated version of the dependency.

### Conditional compilation

We ideally only want to compile a Rescript project as little as possible. So we shouldn't do it per module doc request.

Compilation is simple (as described above). We can check if a package has been compiled or not by checking if the Rescript intermediate outputs
(ex. `lib/bs/src/Main.d`) exist. If they do, project should be compiled properly.

### Basic flow for `fetchDocs`

1. Install package locally in some cache directory if it isn't already. Make sure it is a rescript package before installing.
2. Compile the package if it hasn't been compiled already.
3. Run the `Docgen.parseModule` function on it to get the compiled output.

## Initial design thoughts

Poking around GitHub a little bit to see, but I _think_ I want to just handle downloading and installing packages myself in the code
instead of outsourcing to something like Bun or pnpm. Neither have programmatic APIs that are particularly great, and really we only need
a subset of things. 

Idk maybe the solution is just to have package authors generate and submit their own documentation artifacts? Maybe? idk.