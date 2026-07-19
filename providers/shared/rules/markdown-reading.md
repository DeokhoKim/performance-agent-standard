# High-Density Markdown (HDMD) Reading Rules

Def: HDMD → High-Density Markdown.

Requirement: Rules Interpretation: Rules MUST be machine-interpretable and translatable.
- Reading Rule:
  ```text
  FUNCTION ParseHDMD(document)
    FOR EACH line IN document:
      indent = count_leading_spaces(line)
      tag, content = extract_tag_and_content(line)

      # Node scope applies to its line and all its indented children
      parent = FindParentForIndent(indent)
      parent.AddChild(Node(tag, content, indent))
  ```
- Translation Rule:
  ```text
  FUNCTION TranslateNode(node)
    tag_name = Match(node.tag):
      "Def:"                      → "Definition"
      "Req:" / "Requirement:"     → "Requirement"
      "Rule:"                     → "Rule"
      "Explain:" / "Explanation:" → "Explanation"
      "Step:"                     → "Step"
      DEFAULT                     → "Text"

    IF "→" IN node.content:
      term, val = split(node.content, "→")
      RETURN f"[{tag_name}] '{term.strip()}' translates to '{val.strip()}'."

    RETURN f"[{tag_name}] {node.content} (Context: {node.parent.content})"
  ```

**Tag Translation Reference:**
| Tag | Meaning | Usage |
| :--- | :--- | :--- |
| `Section:` | Section | Denotes a major heading or logical grouping. |
| `Req:` / `Requirement:` | Requirement | A high-level goal or functional necessity. |
| `Rule:` | Rule | A strict guideline or constraint that must be followed. Usually represented as nested bullets (`-`) under a Requirement. |
| `Def:` / `Definition:` | Definition | Explains a term, concept, or variable. |
| `Explain:` / `Explanation:` | Explanation | Provides background context or reasoning (meta-commentary). |
| `Step:` | Step | Used for sequential actions or checklists. |

Section: Language Standards Resolution
Req: Standards Reading Sequence: Read rules from general to specific.
- Rule: Load Order: Rules MUST be loaded and read in the following sequential order:
  1. Common Language Standards (general principles).
  2. Native Language Standards (optional, native-specific).
  3. Language-Specific Standards (Rust, Bash, etc., concrete implementations).
- Rule: Non-Redundant Expansion: Specific standards expand the scope and implementation details of general standards without repeating the general standard's text.

Req: Standards Resolution Precedence: Resolve conflicts by preferring specific rules.
- Rule: Precedence Hierarchy: If rules conflict or overlap, they MUST be resolved in the following priority order:
  1. Language-Specific Standards - Highest priority.
  2. Native Language Standards - Medium priority.
  3. Common Language Standards - Lowest priority.
- Rule: Higher-priority rules override matching rules at lower-priority levels.
