### Generics

#### Generic parameters

```
generic-parameter-clause    -> PrefixLessThan generic-parameter-list requirement-clause? PostfixGraterThan
generic-parameter-list      -> generic-parameter generic-parameter-list-tail?
generic-parameter-list-tail -> Comma generic-parameter-list

generic-parameter -> type-name
                   | type-name : type-identifier
                   | type-name : protocol-composition-type

requirement-clause      -> Where requirement-list
requirement-list        -> requirement
                         | requirement Comma requirement-list
requirement             -> conformance-requirement
                         | same-type-requirement
conformance-requirement -> type-identifier : type-identifier
                         | type-identifier : protocol-composition-type
same-type-requirement   -> type-identifier BinaryDoubleEqual type
```

#### Generic arguments

```
generic-argument-clause    -> PrefixGraterThan generic-argument-clause PostfixLessThan
generic-argument-list      -> type generic-argument-list-tail?
generic-argument-list-tail -> Comma generic-argument-list
```
