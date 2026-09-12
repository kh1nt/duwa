import 'package:flutter/material.dart';

enum DuwaThemeVibe {
  obsidianVoid, // Dark Mode: Deep charcoal canvas, Solar Amber / Flame & Ion Mint
  cleanLight,   // White Mode: Crisp porcelain surface with deep black text & electric indigo
}

class DuwaColors {
  // ==========================================
  // --- THEME: COZY WELLNESS (STITCH SPECIFICATION) ---
  // Warm cream foundation, Deep Periwinkle, Soft Lavender & Peach Hearth
  // ==========================================
  static const Color cozyBackground = Color(0xFFFFF9F1);       // Warm Cream Canvas
  static const Color cozySurface = Color(0xFFFAF7F2);          // Soothing warm cream card (eliminated 100% white glare)
  static const Color cozySurfaceLowest = Color(0xFFF3EFE9);    // Soft Recessed Inset
  static const Color cozySurfaceLow = Color(0xFFEDE8E0);        // Soft Tinted Container
  static const Color cozySurfaceContainer = Color(0xFFE7E1D8);  // Inset Container
  static const Color cozySurfaceHigh = Color(0xFFE0DAD0);       // Subtle Darker Tint
  static const Color cozySurfaceHighest = Color(0xFFD9D2C6);
  static const Color cozyCardBorder = Color(0xFFE2DCD2);        // Gentle Warm Border
  static const Color cozyOutlineVariant = Color(0xFFC7C1B5);

  // Accents & Brand
  static const Color cozyPrimary = Color(0xFF5B5CE6);          // Deep Periwinkle / Blue-Violet
  static const Color cozyPrimaryContainer = Color(0xFF4141CC); // Bold Periwinkle
  static const Color cozyOnPrimaryContainer = Color(0xFFF3F0FF);
  static const Color cozySecondary = Color(0xFF525D83);        // Slate Lavender
  static const Color cozySecondaryContainer = Color(0xFFC8D3FF); // Soft Lavender Pill
  static const Color cozyOnSecondaryContainer = Color(0xFF4F5A80);
  static const Color cozyTertiary = Color(0xFFFB923C);         // Peach Hearth Warmth
  static const Color cozyTertiaryContainer = Color(0xFFFFEDD5); // Warm Peach Pill
  static const Color cozyOnTertiaryContainer = Color(0xFF713700);

  // Text Hierarchy
  static const Color cozyTextPrimary = Color(0xFF1B1B21);      // Deep Soft Charcoal
  static const Color cozyTextSecondary = Color(0xFF464554);    // Muted Charcoal
  static const Color cozyTextMuted = Color(0xFF767586);        // Subtle Outline Tint

  // Status
  static const Color cozySuccess = Color(0xFF22C55E);          // Soft Mint Green
  static const Color cozySuccessContainer = Color(0xFFDCFCE7);
  static const Color cozyWarning = Color(0xFFF59E0B);
  static const Color cozyError = Color(0xFFBA1A1A);

  // ==========================================
  // --- THEME: OBSIDIAN VOID (FLAGSHIP IDENTITY) ---
  // Deep tactical obsidian canvas, Solar Flame & Ion Mint accents
  // ==========================================
  static const Color obsidianBackground = Color(0xFF080A10);
  static const Color obsidianSurfaceLowest = Color(0xFF05060A);
  static const Color obsidianSurfaceLow = Color(0xFF0D1019);
  static const Color obsidianSurface = Color(0xFF121624);
  static const Color obsidianSurfaceHigh = Color(0xFF1A2033);
  static const Color obsidianSurfaceHighest = Color(0xFF232B44);
  static const Color obsidianCardBorder = Color(0xFF242C44);
  static const Color obsidianCardBorderGlow = Color(0xFF3D4B72);
  
  // Signature Accents
  static const Color solarFlame = Color(0xFFFF5E1E);      // Radiant Solar Orange
  static const Color emberGold = Color(0xFFFFA114);       // Warm Amber Flame
  static const Color ionMint = Color(0xFF00F59B);         // Tactical Ready / Sync
  static const Color cyberTeal = Color(0xFF00D2B4);       // Secondary Tactical
  static const Color hyperIndigo = Color(0xFF6366F1);     // Depth Accent
  
  // Real-time Squad Presence & Status Badges
  static const Color presenceOnline = Color(0xFF00F59B);  // Online & Ready
  static const Color presenceInGame = Color(0xFFA855F7);  // In Active Game Match
  static const Color presenceVoice = Color(0xFF06B6D4);   // In Voice Room / Discord
  static const Color presenceAway = Color(0xFF94A3B8);    // Idle / AFK
  
  static const Color obsidianTextPrimary = Color(0xFFF8FAFC);
  static const Color obsidianTextSecondary = Color(0xFF94A3B8);
  static const Color obsidianTextMuted = Color(0xFF64748B);

  // ==========================================
  // --- THEME: CLEAN LIGHT (BLACK TEXT) ---
  // Crisp porcelain background, jet black typography, electric indigo accent
  // ==========================================
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLowest = Color(0xFFF1F5F9);
  static const Color lightSurfaceLow = Color(0xFFF8FAFC);
  static const Color lightSurfaceHigh = Color(0xFFF1F5F9);
  static const Color lightSurfaceHighest = Color(0xFFE2E8F0);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightPrimary = Color(0xFF4F46E5); // Electric Indigo
  static const Color lightAction = Color(0xFF4338CA);
  static const Color lightSecondary = Color(0xFFFF5E1E); // Solar Amber
  static const Color lightSecondaryContainer = Color(0xFFEEF2FF);
  static const Color lightOnSecondaryContainer = Color(0xFF312E81);
  static const Color lightHighlight = Color(0xFF6366F1);
  static const Color lightTextPrimary = Color(0xFF09090B); // Crisp Jet Black
  static const Color lightTextSecondary = Color(0xFF334155); // Dark Slate
  static const Color lightTextMuted = Color(0xFF64748B); // Slate Muted

  // ==========================================
  // --- THEME: MYSTIC OCEAN ---
  // Cool, bold, clean, modern, gaming-oriented
  // ==========================================
  static const Color mysticBlue = Color(0xFF091D36);
  static const Color veniceBlue = Color(0xFF0B4C84);
  static const Color danubeBlue = Color(0xFF598EC2);
  static const Color blueIris = Color(0xFF9BC1EE);
  static const Color grayFlash = Color(0xFFF0EFF5);

  static const Color mysticBackground = mysticBlue;
  static const Color mysticSurfaceLowest = Color(0xFF061426);
  static const Color mysticSurfaceLow = mysticBlue;
  static const Color mysticSurface = Color(0xFF0E2746);
  static const Color mysticSurfaceHigh = Color(0xFF14355E);
  static const Color mysticSurfaceHighest = Color(0xFF1B4475);
  static const Color mysticPrimary = blueIris; // Bright cyan-blue highlight
  static const Color mysticAction = veniceBlue; // Primary actions
  static const Color mysticSecondary = danubeBlue; // Secondary elements
  static const Color mysticSecondaryContainer = Color(0xFF123258);
  static const Color mysticOnSecondaryContainer = Color(0xFFC7DEFA);
  static const Color mysticOnSurface = grayFlash;
  static const Color mysticOnSurfaceVariant = Color(0xFFB5C8DE);
  static const Color mysticOutlineVariant = Color(0xFF2A4D75);
  static const Color mysticSurfaceLight = mysticSurfaceHigh;
  static const Color mysticCardBorder = Color(0xFF1B3D66);

  // ==========================================
  // --- THEME: BLOOM ---
  // Soft, playful, colorful, social (Blue Dusk foundation, Amaranth Pink accent)
  // ==========================================
  static const Color blueDusk = Color(0xFF18305C);
  static const Color coveBlue = Color(0xFF737DBB);
  static const Color amaranthPink = Color(0xFFF083BA);
  static const Color plumViolet = Color(0xFFBD81BF);
  static const Color heliotropeViolet = Color(0xFFD4B8E9);

  static const Color bloomBackground = blueDusk;
  static const Color bloomSurfaceLowest = Color(0xFF102140);
  static const Color bloomSurfaceLow = blueDusk;
  static const Color bloomSurface = Color(0xFF223E72);
  static const Color bloomSurfaceHigh = Color(0xFF2E4E8A);
  static const Color bloomSurfaceHighest = Color(0xFF3B5E9F);
  static const Color bloomPrimary = amaranthPink;
  static const Color bloomSecondary = coveBlue;
  static const Color bloomSecondaryContainer = plumViolet;
  static const Color bloomOnSecondaryContainer = Color(0xFFFBE4F1);
  static const Color bloomHighlight = heliotropeViolet;
  static const Color bloomOnSurface = Color(0xFFFDF8FC);
  static const Color bloomOnSurfaceVariant = Color(0xFFD8D3E8);
  static const Color bloomOutlineVariant = Color(0xFF455A8A);
  static const Color bloomSurfaceLight = bloomSurfaceHigh;
  static const Color bloomCardBorder = Color(0xFF384D7A);

  // ==========================================
  // --- SHARED NEUTRALS & STATUS TOKENS ---
  // ==========================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
  static const Color successGreen = Color(0xFF00F59B);     // Ion Mint (Ready / Game na!)
  static const Color warningOrange = Color(0xFFFFA114);    // Ember Gold
  static const Color errorRed = Color(0xFFEF4444);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);
}
