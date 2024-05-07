/* eslint-disable @typescript-eslint/no-var-requires */
const path = require('path');

module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: './tsconfig.json',
    ecmaFeatures: {
      jsx: true,
    },
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:storybook/recommended',
  ],
  plugins: [
    'unused-imports',
    // 'disable-autofix',
    'react',
    '@typescript-eslint',
    'functional',
    'import',
    'jest',
  ],
  settings: {
    'import/resolver': {
      node: {
        paths: [path.resolve(__dirname, '')],
        extensions: ['.js', '.jsx', '.ts', '.tsx'],
      },
      typescript: {
        project: path.resolve(__dirname, './tsconfig.json'),
      },
    },
    'import/external-module-folders': ['.yarn'],
  },
  env: {
    browser: true,
    es2021: true,
    node: true,
    'jest/globals': true,
  },
  ignorePatterns: ['dist', 'node_modules', 'examples', 'scripts'],
  rules: {
    // General
    indent: ['error', 2],
    'comma-dangle': 'off',
    'no-console': ['warn', { allow: ['debug', 'warn', 'error'] }],
    'no-duplicate-imports': 'off',
    'no-invalid-this': 'off',
    'no-loop-func': 'off',
    'no-loss-of-precision': 'off',
    'no-redeclare': 'off',
    'no-shadow': 'off',
    'no-throw-literal': 'off',
    'no-unused-expressions': 'off',
    'no-return-await': 'off',
    semi: 'off',
    'space-before-function-paren': 'off',
    'unused-imports/no-unused-imports': 'error',
    'unused-imports/no-unused-vars': [
      'warn',
      { vars: 'all', varsIgnorePattern: '^_', args: 'after-used', argsIgnorePattern: '^_' },
    ],
    'arrow-parens': ['error', 'always'],

    // React
    'react/jsx-boolean-value': 'warn',
    'react/jsx-curly-brace-presence': 'warn',
    'react/jsx-fragments': 'warn',
    'react/jsx-no-useless-fragment': 'warn',
    'react/jsx-uses-react': 'off',
    'react/prefer-stateless-function': 'warn',
    'react/prop-types': 'off',
    'react/react-in-jsx-scope': 'off',

    // Functional
    // 'functional/prefer-readonly-type': [
    //   'error',
    //   {
    //     allowLocalMutation: true,
    //     allowMutableReturnType: true,
    //     ignoreClass: true
    //   }
    // ],
    'import/order': [
      'error',
      {
        groups: ['builtin', 'external', 'internal'],
        pathGroups: [
          {
            pattern: '{react,react-dom/**}',
            group: 'external',
            position: 'before',
          },
        ],
        pathGroupsExcludedImportTypes: ['react'],
        'newlines-between': 'always',
        alphabetize: {
          order: 'asc',
          caseInsensitive: true,
        },
      },
    ],
    'linebreak-style': ['error', 'unix'],
    eqeqeq: ['error', 'always', { null: 'ignore' }],
    camelcase: ['warn', { properties: 'never' }],
    quotes: ['error', 'single', { avoidEscape: true }],
  },
  overrides: [{
    files: ['**/*.ts', '**/*.tsx'],
    extends: [
      // 'standard-with-typescript',
      'plugin:@typescript-eslint/recommended',
    ],
    plugins: ['typescript-formatter'],
    rules: {
      indent: 'off',
      // TypeScript
      '@typescript-eslint/comma-dangle': ['error', 'always-multiline'],
      '@typescript-eslint/semi': ['error', 'always'],
      '@typescript-eslint/space-before-function-paren': ['error', {
        anonymous: 'never',
        named: 'never',
        asyncArrow: 'always',
      }],
      '@typescript-eslint/consistent-type-imports': 'error',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-member-accessibility': 'off',
      '@typescript-eslint/indent': 'off',
      /*
      '@typescript-eslint/indent': [
        'error',
        2,
        {
          SwitchCase: 1,
          ObjectExpression: 1,
          MemberExpression: 1,
          flatTernaryExpressions: false,
          CallExpression: {
            arguments: 1,
          },
          'ignoredNodes': [
            'PropertyDefinition[decorators]',
            'TSUnionType',
            "FunctionExpression[params]:has(Identifier[decorators])",
            'CallExpression[arguments]',              // !!!! VERY IMPORTANT !!!!
          ],
        },
      ],
      */
      '@typescript-eslint/member-delimiter-style': 'off',
      '@typescript-eslint/no-confusing-void-expression': [
        'error',
        {
          ignoreArrowShorthand: true,
          ignoreVoidOperator: true,
        },
      ],
      // '@typescript-eslint/no-duplicate-imports': 'error',
      // '@typescript-eslint/no-implicit-any-catch': 'error',
      '@typescript-eslint/no-invalid-this': 'error',
      '@typescript-eslint/no-invalid-void-type': 'error',
      '@typescript-eslint/no-loop-func': 'error',
      '@typescript-eslint/no-loss-of-precision': 'error',
      '@typescript-eslint/no-parameter-properties': 'off',
      '@typescript-eslint/no-redeclare': 'error',
      '@typescript-eslint/no-shadow': 'error',
      '@typescript-eslint/no-throw-literal': 'error',
      '@typescript-eslint/no-unnecessary-boolean-literal-compare': 'error',
      '@typescript-eslint/no-unnecessary-condition': 'off',
      '@typescript-eslint/no-unnecessary-type-arguments': 'error',
      '@typescript-eslint/no-unused-expressions': 'error',
      '@typescript-eslint/no-unused-vars': 'warn',
      '@typescript-eslint/no-use-before-define': [
        'error',
        {
          variables: true,
          enums: false,
          typedefs: false,
          ignoreTypeReferences: true,
        },
      ],
      '@typescript-eslint/no-misused-promises': 'warn',
      '@typescript-eslint/prefer-enum-initializers': 'error',
      '@typescript-eslint/prefer-for-of': 'error',
      '@typescript-eslint/prefer-includes': 'error',
      '@typescript-eslint/prefer-nullish-coalescing': 'error',
      '@typescript-eslint/prefer-optional-chain': 'error',
      '@typescript-eslint/prefer-string-starts-ends-with': 'error',
      '@typescript-eslint/prefer-ts-expect-error': 'error',
      '@typescript-eslint/promise-function-async': 'error',
      '@typescript-eslint/restrict-plus-operands': 'error',
      '@typescript-eslint/return-await': 'error',
      '@typescript-eslint/strict-boolean-expressions': 'off',
      '@typescript-eslint/switch-exhaustiveness-check': 'error',
      '@typescript-eslint/consistent-type-assertions': 'off',
      '@typescript-eslint/prefer-reduce-type-parameter': 'off',
      'typescript-formatter/format': [
        'warn',
        {
          'baseIndentSize': 0,
          'indentSize': 2,
          'tabSize': 2,
          'newLineCharacter': '\n',
          'convertTabsToSpaces': true,
          'indentStyle': 2,
          'trimTrailingWhitespace': true,
          'insertSpaceAfterCommaDelimiter': true,
          'insertSpaceAfterSemicolonInForStatements': true,
          'insertSpaceBeforeAndAfterBinaryOperators': true,
          'insertSpaceAfterConstructor': false,
          'insertSpaceAfterKeywordsInControlFlowStatements': true,
          'insertSpaceAfterFunctionKeywordForAnonymousFunctions': false,
          'insertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis': false,
          'insertSpaceAfterOpeningAndBeforeClosingNonemptyBrackets': false,
          'insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces': true,
          'insertSpaceAfterOpeningAndBeforeClosingEmptyBraces': false,
          'insertSpaceAfterOpeningAndBeforeClosingTemplateStringBraces': false,
          'insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces': false,
          'insertSpaceAfterTypeAssertion': false,
          'insertSpaceBeforeFunctionParenthesis': false,
          'placeOpenBraceOnNewLineForFunctions': false,
          'placeOpenBraceOnNewLineForControlBlocks': false,
          'insertSpaceBeforeTypeAnnotation': false,
          'indentMultiLineObjectLiteralBeginningOnBlankLine': false,
          'semicolons': 'insert'
        }
      ],
    }
  }],
};
