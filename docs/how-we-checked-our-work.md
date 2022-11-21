# How we checked our work: the SIMULA 67 research basis

The 1.3 compatibility work was checked primarily against the **SIMULA Standard**, dated 25 August 1986, and the Norwegian Computing Center's **SIMULA 67 Common Base Language** material. The standard defines SIMULA as incorporating most of ALGOL 60 and specifies portability/conformity requirements for processors and programs. We did not invent a Simula from vibes; we read the documents, and sometimes the documents read us.

## Grammar areas audited

- Class headings, formal parameters, protection parts, virtual parts, prefix classes, split bodies, and `inner`.
- Procedure headings, value/reference/name transmission modes, result assignment, and procedure parameters.
- Value and reference assignments, object generators, `this`, `qua`, object relations, and conditional object expressions.
- Value and reference `for` lists, `while` elements, and `step ... until` traversal.
- Designational expressions, switch declarations, labels, and `goto`/`go to`.
- `inspect`, `when`, `otherwise`, and qualification.
- Fixed text frames and standard text attributes.
- `Head`, `Link`, `Process`, `Simulation`, activation statements, and scheduling clauses.
- External declarations and source-module boundaries.

## Primary references

1. *SIMULA Standard*, 25 August 1986. Portable Simula project mirror: `https://portablesimula.github.io/github.io/doc/SimulaStandard.pdf`
2. Dahl, Myhrhaug, and Nygaard, *SIMULA 67 Common Base Language*. Norwegian Computing Center publication record: `https://nr.no/en/publication/1082350/`
3. Preserved Common Base Language copy: `https://softwarepreservation.computerhistory.org/ALGOL/manual/Simula-CommonBaseLanguage.pdf`

The compiler test suite does not treat a keyword table as proof of conformance. Each area is classified as native-executable, syntax/semantic-only, intentionally extended, or unavailable in `simula67-conformance.md`. A table of keywords is how you lose arguments; the conformance matrix is how you win them.
