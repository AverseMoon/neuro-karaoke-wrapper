# UI Revamp Phase 2: Core Screens — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the cinematic dark theme from Phase 1 to the five bottom-nav screens (Home, Search, Browse/Library, Radio) and the full player, updating shared components (SongCard, SongListItem) along the way.

**Architecture:** Targeted modifications to existing screens — update card containers, section headers, color usage, and effects to use the Phase 1 foundation (GlassCard, ambientGlow, CinematicBackground, GradientText, CyberLabelStyle, Exo2/Inter typography). Remove hardcoded `Surface` color references. Remove the `padding(bottom = 80.dp)` hack now that the Scaffold handles padding via bottomBar.

**Tech Stack:** Kotlin, Jetpack Compose, Material 3, Phase 1 theme system (Color.kt, Type.kt, NeonEffects.kt, Theme.kt)

---

### File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `ui/components/SongCard.kt` | Modify | Add ambient glow on press, subtle gradient border |
| `ui/components/SongListItem.kt` | Modify | Remove play overlay from thumbnail, use theme surface colors |
| `ui/components/CyanBorderCard.kt` | Modify | Rename to AccentCard, use new theme effects |
| `ui/screens/home/HomeScreen.kt` | Modify | Cinematic section headers, remove bottom padding hack, update cards |
| `ui/screens/search/SearchScreen.kt` | Modify | Update filter chips, section labels, search area styling |
| `ui/screens/library/FavoritesScreen.kt` | Modify | Cinematic header, GlassCard action buttons, accent divider |
| `ui/screens/player/PlayerScreen.kt` | Modify | Update album art effects, gradient progress, play button glow |

---

### Task 1: Update SongCard with cinematic styling

**Files:**
- Modify: `app/src/main/java/com/soul/neurokaraoke/ui/components/SongCard.kt`

- [ ] **Step 1: Read and update SongCard.kt**

Update the GlassCard usage and play button styling. Replace the entire file:

```kotlin
package com.soul.neurokaraoke.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.painter.ColorPainter
import coil.compose.AsyncImage
import com.soul.neurokaraoke.data.model.Song
import com.soul.neurokaraoke.ui.theme.GlassCard

@Composable
fun SongCard(
    song: Song,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    GlassCard(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        cornerRadius = 16.dp,
        backgroundAlpha = 0.5f,
        borderAlpha = 0.1f
    ) {
        Column {
            // Cover image with play button overlay
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(1f)
            ) {
                AsyncImage(
                    model = song.coverUrl,
                    contentDescription = song.title,
                    contentScale = ContentScale.Crop,
                    placeholder = ColorPainter(MaterialTheme.colorScheme.surfaceVariant),
                    error = ColorPainter(MaterialTheme.colorScheme.surfaceVariant),
                    modifier = Modifier
                        .matchParentSize()
                        .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                )

                // Play button — primary with slight transparency
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(8.dp)
                        .size(36.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.9f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.PlayArrow,
                        contentDescription = "Play",
                        tint = MaterialTheme.colorScheme.onPrimary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            // Song info
            Column(
                modifier = Modifier.padding(12.dp)
            ) {
                Text(
                    text = song.title,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onBackground,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = "${song.artist} • ${song.coverArtist}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}
```

Changes: `cornerRadius` 12→16dp, `backgroundAlpha` 0.6→0.5f (more glass), `borderAlpha` added at 0.1f, play button alpha 0.9f, cover clip matches 16dp.

- [ ] **Step 2: Verify compilation**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && ./gradlew compileDebugKotlin 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && git add app/src/main/java/com/soul/neurokaraoke/ui/components/SongCard.kt && git commit -m "feat(ui): update SongCard with cinematic glassmorphism styling"
```

---

### Task 2: Update SongListItem — cleaner thumbnail, remove play overlay

**Files:**
- Modify: `app/src/main/java/com/soul/neurokaraoke/ui/components/SongListItem.kt`

- [ ] **Step 1: Read and update SongListItem.kt**

Three targeted changes:

**Change 1:** Remove the persistent play overlay on thumbnails (lines 111-123). The dark overlay with play icon on every thumbnail makes it look cluttered. Delete these lines:

Replace:
```kotlin
            // Play icon overlay
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .background(MaterialTheme.colorScheme.background.copy(alpha = 0.4f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.PlayArrow,
                    contentDescription = "Play",
                    tint = MaterialTheme.colorScheme.onBackground,
                    modifier = Modifier.size(24.dp)
                )
            }
```

With nothing (just delete it). The entire row is already clickable.

**Change 2:** Update the thumbnail corner radius from 4dp to 8dp for a more modern look:

Replace:
```kotlin
                .clip(RoundedCornerShape(4.dp))
                .border(1.dp, singerColor.copy(alpha = 0.5f), RoundedCornerShape(4.dp))
```

With:
```kotlin
                .clip(RoundedCornerShape(8.dp))
                .border(1.dp, singerColor.copy(alpha = 0.4f), RoundedCornerShape(8.dp))
```

**Change 3:** Replace `Primary` import with `MaterialTheme.colorScheme.primary` for the OTHER singer fallback and favorite icon:

Replace:
```kotlin
        Singer.OTHER -> Primary
```

With:
```kotlin
        Singer.OTHER -> MaterialTheme.colorScheme.onSurfaceVariant
```

And replace:
```kotlin
                tint = if (isFavorite) Primary else MaterialTheme.colorScheme.onSurfaceVariant
```

With:
```kotlin
                tint = if (isFavorite) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
```

Then remove the unused `Primary` import:
```kotlin
import com.soul.neurokaraoke.ui.theme.Primary
```

- [ ] **Step 2: Verify compilation**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && ./gradlew compileDebugKotlin 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && git add app/src/main/java/com/soul/neurokaraoke/ui/components/SongListItem.kt && git commit -m "feat(ui): clean up SongListItem — remove play overlay, modernize thumbnail"
```

---

### Task 3: Update CyanBorderCard to AccentCard

**Files:**
- Modify: `app/src/main/java/com/soul/neurokaraoke/ui/components/CyanBorderCard.kt`

- [ ] **Step 1: Update CyanBorderCard**

The card already uses GlassCard internally. Update the styling to be more cinematic — keep the gradient left accent stripe but soften it. Also update corner radius to 16dp:

Replace the entire file:

```kotlin
package com.soul.neurokaraoke.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.unit.dp
import com.soul.neurokaraoke.ui.theme.GlassCard
import com.soul.neurokaraoke.ui.theme.NeonTheme

@Composable
fun CyanBorderCard(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val gradientColors = NeonTheme.colors.gradientColors
    val glowColor = NeonTheme.colors.glowColor

    GlassCard(
        modifier = modifier.fillMaxWidth(),
        cornerRadius = 16.dp,
        backgroundAlpha = 0.5f,
        borderAlpha = 0.06f
    ) {
        Row {
            // Gradient left accent stripe with soft glow
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(topStart = 16.dp, bottomStart = 16.dp))
                    .drawBehind {
                        drawRoundRect(
                            color = glowColor.copy(alpha = 0.2f),
                            topLeft = Offset(-3f, 0f),
                            size = Size(size.width + 6f, size.height),
                            cornerRadius = CornerRadius(4f)
                        )
                    }
                    .background(Brush.verticalGradient(gradientColors))
            )
            // Content
            Box(
                modifier = Modifier
                    .weight(1f)
                    .padding(16.dp)
            ) {
                content()
            }
        }
    }
}
```

Changes: `cornerRadius` 12→16dp, `backgroundAlpha` 0.6→0.5f, `borderAlpha` set to 0.06f (subtler), accent stripe 4→3dp, glow alpha 0.3→0.2f.

- [ ] **Step 2: Verify compilation**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && ./gradlew compileDebugKotlin 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && git add app/src/main/java/com/soul/neurokaraoke/ui/components/CyanBorderCard.kt && git commit -m "feat(ui): soften CyanBorderCard with cinematic glassmorphism"
```

---

### Task 4: Update HomeScreen — cinematic sections, remove bottom padding hack

**Files:**
- Modify: `app/src/main/java/com/soul/neurokaraoke/ui/screens/home/HomeScreen.kt`

- [ ] **Step 1: Update HomeScreen**

Three targeted changes:

**Change 1:** Remove the `padding(bottom = 80.dp)` hack. The Scaffold's bottomBar now handles padding:

Replace:
```kotlin
            .padding(bottom = 80.dp),
```

With:
```kotlin
```

(Remove the line entirely. Keep the comma on the previous line's `.fillMaxSize()`.)

Actually, since the `.fillMaxSize()` is followed by nothing, just remove the padding line. The full modifier chain becomes:

Replace:
```kotlin
        modifier = modifier
            .fillMaxSize()
            .padding(bottom = 80.dp),
```

With:
```kotlin
        modifier = modifier
            .fillMaxSize(),
```

**Change 2:** Update SectionHeader to use `CyberLabelStyle` for the "See All" text and make the title use `GradientText`:

Replace the entire `SectionHeader` composable:

```kotlin
@Composable
private fun SectionHeader(
    title: String,
    onSeeAllClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        if (onSeeAllClick != null) {
            TextButton(onClick = onSeeAllClick) {
                Text(
                    text = "See All",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}
```

With:

```kotlin
@Composable
private fun SectionHeader(
    title: String,
    onSeeAllClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        GradientText(
            text = title,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        if (onSeeAllClick != null) {
            TextButton(onClick = onSeeAllClick) {
                Text(
                    text = "SEE ALL",
                    style = CyberLabelStyle,
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.7f)
                )
            }
        }
    }
}
```

**Change 3:** Replace the hardcoded `Surface` color in `GenreRow` with the theme system:

Replace:
```kotlin
            .background(Surface)
```

With:
```kotlin
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f))
```

**Change 4:** Add the missing imports at the top of the file:

Add these imports (alongside existing ones):
```kotlin
import com.soul.neurokaraoke.ui.theme.CyberLabelStyle
import com.soul.neurokaraoke.ui.theme.GradientText
```

And remove the unused `Surface` import:
```kotlin
import com.soul.neurokaraoke.ui.theme.Surface
```

- [ ] **Step 2: Verify compilation**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && ./gradlew compileDebugKotlin 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && git add app/src/main/java/com/soul/neurokaraoke/ui/screens/home/HomeScreen.kt && git commit -m "feat(ui): update HomeScreen with gradient headers, cyber labels, remove padding hack"
```

---

### Task 5: Update SearchScreen — filter chip styling, cyber labels

**Files:**
- Modify: `app/src/main/java/com/soul/neurokaraoke/ui/screens/search/SearchScreen.kt`

- [ ] **Step 1: Read SearchScreen.kt and apply targeted changes**

Read the file first. Then make these changes:

**Change 1:** The SearchScreen already uses `CyberLabelStyle` in several places — good. Find any hardcoded bottom padding for the mini player and remove it.

Search for `padding(bottom = ` in the file. If present (e.g., `80.dp` or similar), remove it — Scaffold handles this now.

**Change 2:** Update the sort dropdown background color for better visibility:

Find the sort dropdown section. If it uses `surfaceVariant.copy(alpha = 0.5f)`, update to:
```kotlin
MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
```

This gives better contrast on the darker backgrounds.

**Change 3:** If the `SingerFilterChip` composable uses hardcoded singer colors, make sure it imports from the theme:

The filter chips likely use `NeuroColor`, `EvilColor`, `DuetColor` — these are fine, they're theme-defined.

- [ ] **Step 2: Verify compilation**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && ./gradlew compileDebugKotlin 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && git add app/src/main/java/com/soul/neurokaraoke/ui/screens/search/SearchScreen.kt && git commit -m "feat(ui): update SearchScreen with cinematic styling adjustments"
```

---

### Task 6: Update FavoritesScreen — cinematic header and action buttons

**Files:**
- Modify: `app/src/main/java/com/soul/neurokaraoke/ui/screens/library/FavoritesScreen.kt`

- [ ] **Step 1: Read FavoritesScreen.kt and apply targeted changes**

Read the file first. Then apply:

**Change 1:** Update the gradient overlay alpha values on the header background. Find the vertical gradient overlay (lines around 104-111). Update the alpha stops for a smoother fade:

Replace the gradient overlay colors (find the `Brush.verticalGradient` block in the header):
```kotlin
colors = listOf(
    MaterialTheme.colorScheme.background.copy(alpha = 0.3f),
    MaterialTheme.colorScheme.background.copy(alpha = 0.6f),
    MaterialTheme.colorScheme.background
)
```

With:
```kotlin
colors = listOf(
    MaterialTheme.colorScheme.background.copy(alpha = 0.1f),
    MaterialTheme.colorScheme.background.copy(alpha = 0.5f),
    MaterialTheme.colorScheme.background.copy(alpha = 0.85f),
    MaterialTheme.colorScheme.background
)
```

This gives a smoother gradient from the blurred cover art into the background — more cinematic.

**Change 2:** Update action button backgrounds from `surfaceVariant.copy(alpha = 0.5f)` to use the surface color. Find all instances of:

```kotlin
.background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
```

Replace with:
```kotlin
.background(MaterialTheme.colorScheme.surface.copy(alpha = 0.7f))
```

**Change 3:** Update the empty state icon alpha. Find:
```kotlin
MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
```

Replace with:
```kotlin
MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
```

(More subtle on the darker background.)

**Change 4:** Remove any hardcoded bottom padding for the mini player (e.g., `padding(bottom = 80.dp)` or similar).

- [ ] **Step 2: Verify compilation**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && ./gradlew compileDebugKotlin 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && git add app/src/main/java/com/soul/neurokaraoke/ui/screens/library/FavoritesScreen.kt && git commit -m "feat(ui): update FavoritesScreen with cinematic header and refined buttons"
```

---

### Task 7: Update PlayerScreen — cinematic album art and controls

**Files:**
- Modify: `app/src/main/java/com/soul/neurokaraoke/ui/screens/player/PlayerScreen.kt`

This file is 1611 lines. Make ONLY these targeted changes — do not rewrite the file.

- [ ] **Step 1: Read PlayerScreen.kt header and album art section (lines 1-260)**

- [ ] **Step 2: Update album art container styling**

The album art currently uses `neonBorder()` (backward-compat alias). Update it to use the new name and adjust the styling:

Replace:
```kotlin
                .neonBorder(
                    colors = NeonTheme.colors.borderColors,
                    borderWidth = 1.dp,
                    cornerRadius = 16.dp,
                    glowRadius = 4.dp
                )
```

With:
```kotlin
                .gradientBorder(
                    colors = NeonTheme.colors.borderColors,
                    borderWidth = 1.dp,
                    cornerRadius = 16.dp
                )
```

And update the import — replace:
```kotlin
import com.soul.neurokaraoke.ui.theme.neonBorder
```

With:
```kotlin
import com.soul.neurokaraoke.ui.theme.gradientBorder
```

- [ ] **Step 3: Update play button glow**

The play button already uses `animatedNeonGlow()` (backward-compat alias). Update to the new name:

Replace:
```kotlin
                    .then(
                        if (isPlaying) Modifier.animatedNeonGlow(
                            color = NeonTheme.colors.glowColor,
                            baseRadius = 10.dp,
                            cornerRadius = 36.dp
                        ) else Modifier
                    )
```

With:
```kotlin
                    .then(
                        if (isPlaying) Modifier.pulsingGlow(
                            color = NeonTheme.colors.glowColor,
                            baseRadius = 10.dp,
                            cornerRadius = 36.dp
                        ) else Modifier
                    )
```

And update the import — replace:
```kotlin
import com.soul.neurokaraoke.ui.theme.animatedNeonGlow
```

With:
```kotlin
import com.soul.neurokaraoke.ui.theme.pulsingGlow
```

- [ ] **Step 4: Update "View Queue" button styling**

Replace:
```kotlin
        Button(
            onClick = { showQueue = true },
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                contentColor = MaterialTheme.colorScheme.primary
            ),
            shape = RoundedCornerShape(24.dp),
            modifier = Modifier
                .fillMaxWidth(0.6f)
                .height(48.dp)
        ) {
            Text(
                text = "View Queue",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Medium
            )
        }
```

With:
```kotlin
        Button(
            onClick = { showQueue = true },
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.7f),
                contentColor = MaterialTheme.colorScheme.primary
            ),
            shape = RoundedCornerShape(24.dp),
            modifier = Modifier
                .fillMaxWidth(0.6f)
                .height(48.dp)
        ) {
            Text(
                text = "VIEW QUEUE",
                style = CyberLabelStyle,
                color = MaterialTheme.colorScheme.primary
            )
        }
```

Add import at the top of the file:
```kotlin
import com.soul.neurokaraoke.ui.theme.CyberLabelStyle
```

- [ ] **Step 5: Verify compilation**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && ./gradlew compileDebugKotlin 2>&1 | tail -5
```

- [ ] **Step 6: Commit**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && git add app/src/main/java/com/soul/neurokaraoke/ui/screens/player/PlayerScreen.kt && git commit -m "feat(ui): update PlayerScreen with cinematic effects and cyber labels"
```

---

### Task 8: Final compilation check and cleanup

- [ ] **Step 1: Full build check**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && ./gradlew compileDebugKotlin --rerun-tasks 2>&1 | tail -30
```

- [ ] **Step 2: Check for errors**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && ./gradlew compileDebugKotlin --rerun-tasks 2>&1 | grep "error:" | head -20
```

Fix any compile errors found. Common issues:
- Missing imports for `GradientText`, `CyberLabelStyle`, `gradientBorder`, `pulsingGlow`
- Removed imports that are still used somewhere (check before deleting)
- Parameter name changes on components

- [ ] **Step 3: Commit fixes if any**

```bash
cd C:/Users/Aferil/neuro-karaoke/Android && git add -A && git commit -m "fix(ui): resolve Phase 2 compile errors"
```
