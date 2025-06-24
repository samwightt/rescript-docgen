# rescript-docgen

ReScript tool that will generate docs for the current project. VERY early stages.

Currently does the following:

- ReScript config parsing (deps, sources, etc).
- Directory resolution for source files from ReScript config.
- Can call the ReScript analysis tool from `@rescript/tools` with a slightly better API and on any arbitrary module (so long as it's been compiled).