# Architecture violations report

- Scope: `tool/arch_lint_canary/`
- Generated (UTC): `2026-04-02T09:39:39.771106Z`
- Mode: `enforce`
- Violations: **5**

## Summary by rule

- **ARCH-R1**: 1
- **ARCH-R2**: 1
- **ARCH-R3**: 1
- **ARCH-R4**: 1
- **ARCH-R5**: 1

## Details

### ARCH-R2 — tool/arch_lint_canary/lib/src/features/feature_a/domain/usecases/canary_r2_usecase.dart:1

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/feature_a/data/dtos/canary_dto.dart';
```

### ARCH-R3 — tool/arch_lint_canary/lib/src/features/feature_a/presentation/pages/canary_r3_page.dart:1

- **Message**: Interdit: presentation -> SDK externe (dio)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:dio/dio.dart';
```

### ARCH-R4 — tool/arch_lint_canary/lib/src/features/feature_a/presentation/pages/canary_r4_page.dart:1

- **Message**: Interdit: feature "feature_a" -> feature "feature_b"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/feature_b/domain/entities/canary_entity.dart';
```

### ARCH-R5 — tool/arch_lint_canary/lib/src/features/feature_a/presentation/providers/canary_r5_provider.dart:1

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — tool/arch_lint_canary/lib/src/features/feature_a/presentation/widgets/canary_r1_widget.dart:1

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/feature_a/data/dtos/canary_dto.dart';
```

