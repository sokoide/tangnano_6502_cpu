# Product Guide - 6502 CPU on FPGA Learning Journey

## Initial Concept

TangNano 9K/20K と GoWIN IDE を使って、FPGA の開発方法と、必要な知識を身につけ、さらに 8bit CPU 開発を通して実践し、理解を深める。

## Target Users

- FPGA やハードウェア記述言語（SystemVerilog）を学びたい学生
- 6502 CPU やレトロコンピューティングに興味があるエンジニア
- コンピュータアーキテクチャを基礎から深く理解したいホビーユーザー

## Project Goals

- 6502 CPU を SystemVerilog で完全に実装し、Tang Nano 9K/20K 上で動作させる。
- FPGA の基本的な開発フロー（設計、シミュレーション、論理合成、実機検証）を習得する。
- 8bit CPU の実装を通じて、レジスタ、ALU、デコーダ、メモリマップド I/O などのコンピュータアーキテクチャの核心を理解する。
- 最終的に Woz Monitor などの実用的なソフトウェアが動作するシステムを構築する。

## Key Features

- **Step-by-Step Curriculum:** Day01 から Day99 まで、難易度が段階的に上がる学習コンテンツ。
- **Hardware-Native Debugger:** CPU の内部状態を LCD にリアルタイム表示し、視覚的なデバッグを可能にする。
- **Reference Implementations:** 各ステップごとに「完成版」のソースコードを提供し、学習の躓きを防止。
- **Dual Platform Support:** Tang Nano 9K および 20K の両方に対応したプロジェクト構成。

## Success Outcomes

- 低レイヤー（CPU、メモリ、周辺機器）の動作原理に関する深い知識。
- SystemVerilog を用いた実践的なデジタル回路設計スキル。
- 自ら CPU をゼロから構築したという成功体験と、さらなるハードウェア開発への自信。

## Quality Guidelines

- **Reproducibility:** 誰でも README に従えば環境構築から実行まで行えること。
- **Comprehensive Docs:** 各回路の意図や設計思想が明文化されていること。
- **Simulation First:** 実機に書き込む前に、シミュレーションで正しさを検証する習慣を促進する。
- **Test-Driven Learning:** 各ステップに専用のテストベンチを用意し、テストをパスすることを学習の達成基準とする。
