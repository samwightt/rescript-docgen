module Html = {
  @jsx.component
  let make = (~children) => {
    <html>
      <head>
        <title>{Hjsx.string("Test App")}</title>
      </head>
      <body>
        children
      </body>
    </html>
  }
}