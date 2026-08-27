# High-Density Markdown (HDMD) Writing Rules

Def: HDMD → High-Density Markdown.
Def: Core Goal → Maximize meaning per token, eliminate fluff, retain 100% semantic accuracy, && support agent-extraction.

Section: Zero Context Loss (Absolute Priority)
Req: 100% Context Preservation: Capture user intent, rules, && constraints fully without sacrificing semantic accuracy for brevity.
- Rule: Nuance Retention: Retain all constraints, nuances, conditions, && caveats using descriptive language if compaction threatens clarity; ensure text supports perfect reconstruction of original intent.
- Rule: Input Generalization: Distill user inputs into generalized rules && definitions rather than verbatim copying; retain specific examples ONLY when the underlying concept is ambiguous.

Section: Conciseness && Token Efficiency
Req: Token Minimization: Shrink document footprint while maintaining visual && global coherence.
- Rule: Conversational Padding Elimination: Prohibit conversational padding, filler words, && verbose connectives; enforce `&&`, `||`, `!`, `→` where clear, && enclose specific entities in backticks (e.g., `user_profile`).
- Rule: Document Scope Confirmation: Review the entire document when editing to merge new content cleanly without redundancy; if edits exceed the target scope, present changes for user confirmation.

Section: Compact Formatting
Req: Visual Hierarchy: Enforce Markdown structural elements over paragraphs.
- Rule: Scope Indentation: Enforce leading spaces to denote child scope, conditions, || sub-steps.
- Rule: Structural Bulleting: Enforce `-` for parallel items && `1.` for sequential workflows.
- Rule: Relational Data Tables: Enforce Markdown tables for multi-attribute definitions across multiple entities.
- Rule: Pseudocode Process Blocks: Enforce indentation-based pseudocode blocks for complex sequential processes, conditional workflows, || nested logic to eliminate conversational prose && maximize semantic accuracy.

Section: Agent-Extractable Structure
Req: Machine Readability: Ensure semantic readability via standard Markdown parsers && LLM context mapping.
- Rule: Standardized Prefixes: Prefix critical lines with explicit keywords (`Section:`, `Req:`, `- Rule:`, `Def:`, `Step:`).
- Rule: Hierarchical Cohesion: Group interrelated data using Markdown lists && indentation; tag scope applies strictly to its line && all indented child nodes.
- Rule: Inline Semantic Indexing: Append `#topic` || `@agent` to lines for domain filtering && targeted RAG retrieval.
- Rule: Frontmatter Topic Declaration: Documents utilizing inline `#topic` tags MUST declare a YAML frontmatter block at the top (e.g., `topics: [#typing, #standards]`) to enable instant relevance evaluation without full-document parsing.
- Rule: Explicit Block Delimiters: If rigid rule boundaries cannot be solved cleanly by indentation, enclose blocks in native Markdown alerts (e.g., `> [!IMPORTANT]`); prohibit arbitrary line count constraints || XML tags.

Section: Procedural Writing Flow
Req: Writing Procedure: The writing flow MUST follow this logical compilation process.
- Rule: Logical Compilation Flow:
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
