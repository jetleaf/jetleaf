# jetleaf_data Example

Demonstrates core `jetleaf_data` capabilities:

- Entity annotations (`@Entity`, `@Table`, `@Id`, `@Column`, `@CreatedDate`)
- Naming strategies (`SnakeCaseNamingStrategy`) and type converters (`DefaultTypeConverterRegistry`)
- Derived query parsing with `PartTree.parse`
- Multi-dialect query rendering (`PostgreSqlDialect`, `MySqlDialect`, `SqliteDialect`, `MongoDialect`)
- Pagination & sorting (`PageRequest`, `Sort`, `Order`, `Direction`)

## Running

```bash
dart pub get
dart run lib/main.dart
```
