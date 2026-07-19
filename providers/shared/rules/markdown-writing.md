# High-Density Markdown (HDMD) Writing Rules

Def: HDMD → High-Density Markdown.
Def: Core Goal → Maximize meaning per token, eliminate fluff, retain 100% semantic accuracy, support agent-extraction.

## Section 1: Zero Context Loss (Absolute Priority)
Requirement: 100% Context Preservation: Capture the user's intent, rules, and constraints fully without sacrificing semantic accuracy for brevity.
- Rule: Retain all constraints, nuances, conditions, and caveats, using descriptive language if compaction threatens clarity. The text must support perfect reconstruction of the original intent.
- Rule: Distill user inputs into generalized rules and definitions rather than copying verbatim. Retain specific input examples only when the underlying concept is ambiguous.

## Section 2: Conciseness & Token Efficiency
Requirement: Token Minimization: Shrink document footprint while maintaining visual and global coherence.
- Rule: Eliminate conversational padding, filler words, and verbose connectives (preferring `&&`, `||`, `!`, `→` where clear). Enclose specific entities in backticks (e.g., `user_profile`).
- Rule: Edit files by reviewing the entire document to merge new content cleanly, avoiding redundancies. If edits or rewrites exceed the immediate target section/scope, present the changes to the user for confirmation.


## Section 3: Compact Formatting
Requirement: Visual Hierarchy: Use Markdown structural elements instead of paragraphs.
- Indentation: Use spaces to denote scope, conditions, or child steps.
- Bulleting: `-` for parallel items, `1.` for sequential flows.
- Data Tables: Use tables for defining multiple attributes across multiple entities.
- Pseudocode Blocks: Use code blocks containing clean indentation-based pseudocode to describe complex sequential processes, conditional workflows, or nested logic. This eliminates conversational prose and maximizes semantic accuracy.

## Section 4: Agent-Extractable Structure (Semantic-Friendly)
Requirement: Machine Readability: Ensure semantic readability via standard Markdown parsers and LLM context mapping.
- Standardized Prefixes: Prefix critical lines with explicit keywords.
- **Tag Dictionary:**
  | Tag | Meaning | Usage |
  | :--- | :--- | :--- |
  | `Section:` | Section | Denotes a major heading or logical grouping. |
  | `Req:` / `Requirement:` | Requirement | A high-level goal or functional necessity. |
  | `Rule:` | Rule | A strict guideline or constraint that must be followed. Usually represented as nested bullets (`-`) under a Requirement. |
  | `Def:` / `Definition:` | Definition | Explains a term, concept, or variable. |
  | `Explain:` / `Explanation:` | Explanation | Provides background context or reasoning (meta-commentary). |
  | `Step:` | Step | Used for sequential actions or checklists. |
- Hierarchical Cohesion: Data intended to be extracted together MUST be grouped using Markdown lists and indentation. The scope of a tag/keyword applies to the line it is on and all its indented children.
- Inline Indexing: Append `#topic` or `@agent` to lines for domain filtering and targeted RAG retrieval.
- Frontmatter Topic Index: Any document utilizing inline `#topic` tags MUST declare a YAML-style frontmatter block at the very top of the file (e.g., `topics: [#typing, #standards]`). This allows agents to quickly evaluate relevance without parsing the entire document.
- Explicit Block Delimiters: If a rule or requirement requires rigid boundaries that cannot be cleanly solved by indentation, enclose the block in native Markdown blockquotes (e.g., `> [!IMPORTANT]`) rather than using line counts or XML tags.

## Section 5: Procedural Writing Flow (Pseudocode Guide)
Requirement: Writing Procedure: The writing flow MUST follow this logical compilation process:
- Writing Rule:
  ```text
  FUNCTION WriteHDMD(raw_content, existing_doc)
    # 1. Zero Context Loss Verification
    ASSERT preserves_original_nuance(raw_content)
    ASSERT contains_reconstruction_info(raw_content)

    # 2. Token Optimization Loop
    optimized_text = raw_content
    FOR EACH sentence IN raw_content:
      IF is_padding_or_filler(sentence):
        optimized_text.Remove(sentence)
      ELSE IF exists_in(sentence, existing_doc):
        optimized_text.DeduplicateWith(existing_doc)

    # 3. Structural Formatting
    FOR EACH block IN optimized_text:
      block.ApplyMarkdownVisualHierarchy()  # Indentation & bulleting
      block.ReplaceVerboseConnectivesWithSymbols()  # "and" -> &&, "or" -> ||, "implies" -> →
      block.WrapEntitiesInBackticks()       # e.g., `user_profile`

    # 4. Semantic Tagging
    FOR EACH line IN optimized_text:
      IF line.is_section_header():   PREFIX line WITH "Section:"
      IF line.is_goal_necessity():   PREFIX line WITH "Req:"
      IF line.is_constraint_rule():  PREFIX line WITH "Rule:"
      IF line.is_definition():       PREFIX line WITH "Def:"
      IF line.is_step():             PREFIX line WITH "Step:"

    # 5. Topic Indexing Check
    IF optimized_text.has_inline_topic_tags():
      optimized_text.AddFrontmatter(topics = extract_topic_tags(optimized_text))

    RETURN optimized_text
  ```
