### Solidity Style Guide

https://docs.soliditylang.org/en/latest/style-guide.html

### Chainlink Style Guide

https://github.com/smartcontractkit/chainlink/blob/develop/contracts/STYLE_GUIDE.md

### Layout and Ordering of Functions

https://docs.soliditylang.org/en/latest/style-guide.html#order-of-layout

Contract elements should be laid out in the following order:

1. Pragma statements
2. Import statements
3. (outside contract) Events
4. (outside contract) Errors
5. Interfaces
6. Libraries
7. Contracts

---

Inside each contract, library or interface, use the following order:

1. Type declarations
2. State variables
3. Events
4. Errors
5. Modifiers
6. Functions

**NOTE:** It might be clearer to declare types close to their use in events or state variables.

`HTTPServerError` is better than `HttpServerError`

`xmlHTTPRequest` is better than `XMLHTTPRequest`

---

https://docs.soliditylang.org/en/latest/style-guide.html#order-of-functions

Functions should be grouped according to their visibility and ordered:

- constructor
- receive function (if exists)
- fallback function (if exists)
- external
- external functions that are view
- external functions that are pure
- public
- public functions that are view
- public functions that are pure (and so on)
- internal
- private

Within a grouping, place the `view` and `pure` functions last.

---

https://docs.soliditylang.org/en/latest/style-guide.html#function-declaration

The modifier order for a function should be:

1. Visibility
2. Mutability
3. Virtual
4. Override
5. Custom modifiers