# source metrics

the current 1.6.1 source tree contains

- 57,040 physical lines in the object pascal compiler/driver source count
- 29 compiler units plus the tiny `fsim.lpr` driver
- 43 free simula standard-library modules
- 240 generated executable conformance programs
- 195 token kinds, 97 ast node kinds, 144 ir opcodes and 162 recognized keywords
- 7 object pascal unit-test programs registered by the api audit
- 142 handwritten x86 emitter procedures covered by the generated-label audit
- 380 simula/fsim sources covered by the repository lexical source gate

large generated unicode tables are real source data but live in their own unit so generated classification data is not confused with handwritten compiler structure
