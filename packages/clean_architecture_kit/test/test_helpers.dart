// test/test_helpers.dart

// THE DEFINITIVE FIX:
// The testing utilities are exported from `package:custom_lint/testing.dart`,
// not from the `custom_lint_builder` package.
export 'package:custom_lint/testing.dart'
    show
    // The function to run a lint against a file.
    testLint,
    // The function to create a file in the in-memory test environment.
    createFile,
    // A helper to create the root pubspec.yaml for the test project.
    createPubspec;