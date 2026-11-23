# 008 — PasswordEncoder family

## Design reference
A `PasswordEncoder` family with a `DelegatingPasswordEncoder` for self-describing hashes and algorithm migration, a `PasswordEncoderFactories` default factory, and BCrypt, Argon2id, and PBKDF2 implementations.

## Problem
Stored hashes can outlive the algorithm that created them. Without an `{id}` prefix and a delegating encoder, an algorithm migration requires a flag day. Hostile stored hashes can also request unbounded work.

## Invariant
1. Every encoded hash MUST be self-describing where the format allows it, and `DelegatingPasswordEncoder` MUST resolve the `{id}` prefix to the right encoder.
2. An unknown `{id}` MUST throw a clear exception, never fall back to a weaker encoder.
3. Parsed parameters (`m`, `t`, `p`, iterations, bcrypt cost) MUST be bounded by configurable maxima before any derivation work is performed.
4. Comparisons MUST be constant-time.
5. An async API MUST exist for expensive derivations so the isolate event loop is not blocked.
6. Encoder outputs MUST match published external vectors, not self-generated round-trips.

## Extension seam
`PasswordEncoder` is a public interface; `DelegatingPasswordEncoder` accepts a map of ids to encoders; `PasswordEncoderFactories` provides the fluent default factory.

## Edge cases
Malformed PHC string; version other than `v=19`; bcrypt radix64 with an invalid 4th character; bcrypt strength 31 (`1 << 31` rounds); a stored hash with `m` in the terabytes; Unicode and 72-byte boundary passwords.

## Jetleaf mapping
Keep `Argon2idPasswordEncoder` as the class name — it names the exact algorithm (owner decision). Keep the three existing encoders and harden them. `pointycastle` remains the primitive. Pin it to a single major version.

## Gating tests
- `delegating_encoder_resolves_id_prefix`
- `unknown_id_throws`
- `argon2_rfc9106_vectors`
- `bcrypt_published_vectors_including_72_byte_boundary`
- `pbkdf2_nist_vectors`
- `hostile_phc_parameters_rejected_without_derivation`
- `bcrypt_strength_31_rejected` (fails today)
- `async_encode_does_not_block_event_loop`
