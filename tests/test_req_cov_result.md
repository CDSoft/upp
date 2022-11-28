## Coverage

### Coverage matrix

+----------------------------------+------------------------------+
| **File**                         | **[`spec.html`](spec.html)** |
+==================================+==============================+
| [`R_SPEC_1`](spec.html#R_SPEC_1) | title of SPEC 1              |
+----------------------------------+------------------------------+
| [`R_SPEC_2`](spec.html#R_SPEC_2) | title of SPEC 2              |
+----------------------------------+------------------------------+
| [`R_SPEC_3`](spec.html#R_SPEC_3) | title of SPEC 3              |
+----------------------------------+------------------------------+
| [`R_SPEC_4`](spec.html#R_SPEC_4) | title of SPEC 4              |
+----------------------------------+------------------------------+

+----------------------------------+-------------------------------------------------------+
| **File**                         | **[`code.html`](code.html)**                          |
+==================================+=======================================================+
| [`R_CODE_A`](code.html#R_CODE_A) | title of CODE A                                       |
|                                  |                                                       |
|                                  | - *[`R_SPEC_1`](spec.html#R_SPEC_1)*: title of SPEC 1 |
|                                  | - *[`R_SPEC_2`](spec.html#R_SPEC_2)*: title of SPEC 2 |
+----------------------------------+-------------------------------------------------------+
| [`R_CODE_B`](code.html#R_CODE_B) | title of CODE B                                       |
|                                  |                                                       |
|                                  | - *[`R_SPEC_2`](spec.html#R_SPEC_2)*: title of SPEC 2 |
|                                  | - *[`R_SPEC_3`](spec.html#R_SPEC_3)*: title of SPEC 3 |
+----------------------------------+-------------------------------------------------------+

+----------------------------------+-------------------------------------------------------+
| **File**                         | **[`test.html`](test.html)**                          |
+==================================+=======================================================+
| [`R_TEST_X`](test.html#R_TEST_X) | title of TEST X [PASS]                                |
|                                  |                                                       |
|                                  | - *[`R_SPEC_1`](spec.html#R_SPEC_1)*: title of SPEC 1 |
|                                  | - *[`R_SPEC_2`](spec.html#R_SPEC_2)*: title of SPEC 2 |
+----------------------------------+-------------------------------------------------------+
| [`R_TEST_Y`](test.html#R_TEST_Y) | title of TEST Y [FAIL]                                |
|                                  |                                                       |
|                                  | - *[`R_SPEC_2`](spec.html#R_SPEC_2)*: title of SPEC 2 |
+----------------------------------+-------------------------------------------------------+
| [`R_TEST_Z`](test.html#R_TEST_Z) | title of TEST Z [N/E]                                 |
|                                  |                                                       |
|                                  | - *[`R_SPEC_3`](spec.html#R_SPEC_3)*: title of SPEC 3 |
+----------------------------------+-------------------------------------------------------+

### Dependency graph

```{.dot render="{{dot}}"}
digraph {
graph [rankdir=LR];
fontsize=10
node [style=filled, color=lightgrey, shape=none, fontsize=8, margin=0, height=0.16]
subgraph cluster_1 {
  label = "spec.html";
  R_SPEC_1[URL="spec.html#R_SPEC_1", color=cyan];
  R_SPEC_2[URL="spec.html#R_SPEC_2", color=cyan];
  R_SPEC_3[URL="spec.html#R_SPEC_3", color=cyan];
  R_SPEC_4[URL="spec.html#R_SPEC_4", color=orange];
}
subgraph cluster_2 {
  label = "code.html";
  R_CODE_A[URL="code.html#R_CODE_A", color=orange];
  R_CODE_B[URL="code.html#R_CODE_B", color=orange];
}
subgraph cluster_3 {
  label = "test.html";
  R_TEST_X[URL="test.html#R_TEST_X", color=green];
  R_TEST_Y[URL="test.html#R_TEST_Y", color=red];
  R_TEST_Z[URL="test.html#R_TEST_Z", color=yellow];
}
R_SPEC_1 -> R_CODE_A
R_SPEC_2 -> R_CODE_A
R_SPEC_2 -> R_CODE_B
R_SPEC_3 -> R_CODE_B
R_SPEC_1 -> R_TEST_X
R_SPEC_2 -> R_TEST_X
R_SPEC_2 -> R_TEST_Y
R_SPEC_3 -> R_TEST_Z
}
```
