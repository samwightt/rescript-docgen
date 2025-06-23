let binaryPath = RescriptTools.getBinaryPath()

/**
 Rescript Bun doesn't have the ShellError type built in, so we have to build our own. Yay.
 */
module ShellError = {
  type shellError
  @module("bun") @val @scope("$") external shellError: shellError = "ShellError"

  @get external cause: shellError => option<string> = "cause"
  @get external message: shellError => string = "message"
  @get external exitCode: shellError => int = "exitCode"
  @get external stderr: shellError => RescriptBun.Buffer.t = "stderr"
  @get external stdout: shellError => RescriptBun.Buffer.t = "stdout"
  @send external text: shellError => string = "text"

  let stderrText = (err: shellError): string => {
    err->stderr->RescriptBun.Buffer.toString
  }

  external convert: Exn.t => shellError = "%identity"

  let instanceof = (exn: Exn.t, value): bool => {
    %raw(`exn instanceof value`)
  }

  let isShellError = instanceof(_, shellError)

  let toShellError = (exn: Exn.t): option<shellError> => {
    if isShellError(exn) {
      Some(convert(exn))
    } else {
      None
    }
  }
}

/**
 Types of errors we can have.
 */
type parseError = FileDoesNotExist

/**
 Checks to see if the given exn is a file doesn't exist error.
 It's a file doesn't exist error if the error message contains "No such file or directory".
 */
let isFileDoesntExistError = (exn: Exn.t): bool => {
  switch exn->ShellError.toShellError->Option.map(ShellError.stderrText) {
  | Some(text) => text->String.includes("No such file or directory")
  | None => false
  }
}

let parseModule = async (path: string): result<RescriptTools.Docgen.doc, parseError> => {
  open RescriptBun.Globals
  try {
    let res = await (sh`${binaryPath} doc ${path}`)->ShellPromise.quiet->ShellPromise.text
    let json = JSON.parseExn(res)
    let res = RescriptTools.Docgen.decodeFromJson(json)
    Ok(res)
  } catch {
  // RescriptTools throws an error if the file doesn't exist, which Bun rethrows (yay).
  // Check if it's that error by checking if the string contains what we expect. If not, re-raise it.
  | Exn.Error(err) => if isFileDoesntExistError(err) {
      Error(FileDoesNotExist)
    } else {
      panic("Unexpected error occurred")
    }
  }
}
