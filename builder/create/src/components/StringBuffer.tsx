/**
 * A lightweight utility class for efficiently building multi-line strings.
 *
 * This `StringBuffer` implementation provides two main operations:
 * - `writeln()` — appends a new line (optionally with content)
 * - `write()` — appends text to the current line without creating a new one
 *
 * Internally, each line is stored as an entry in an array, ensuring efficient
 * concatenation and predictable newline handling. This is particularly useful
 * when generating source code, configuration files, or other structured text
 * output.
 */
export default class StringBuffer {
  /** Internal list of lines that make up the buffer. */
  private parts: string[] = [];

  /**
   * Appends a new line to the buffer.
   *
   * @param line Optional text to include on the new line. Defaults to an empty line.
   *
   * Example:
   * ```ts
   * buffer.writeln("class Example {");
   * buffer.writeln();
   * buffer.writeln("}");
   * ```
   */
  writeln(line: string = "") {
    this.parts.push(line);
  }

  /**
   * Appends content to the current line without adding a newline.
   *
   * If the buffer is currently empty, the text starts the first line.
   * Otherwise, it is appended to the end of the most recent line.
   *
   * @param line The text to append to the current line.
   *
   * Example:
   * ```ts
   * buffer.write("Hello");
   * buffer.write(" World"); // same line → "Hello World"
   * ```
   */
  write(line: string) {
    if (this.parts.length === 0) {
      this.parts.push(line);
    } else {
      this.parts[this.parts.length - 1] += line;
    }
  }

  /**
   * Converts the internal buffer into a full string.
   *
   * Each stored line is joined using a newline separator (`\n`).
   *
   * @returns The complete assembled multi-line string.
   */
  toString() {
    return this.parts.join("\n");
  }
}