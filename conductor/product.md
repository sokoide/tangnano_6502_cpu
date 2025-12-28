# Product Guide - 6502 CPU on FPGA Learning Journey

## Initial Concept

TangNano 9K/20KとGoWIN IDEを使って、FPGAの開発方法と、必要な知識を身につけ、さらに8bit CPU開発を通して実践し、理解を深める。

## Target Users

- FPGAやハードウェア記述言語（SystemVerilog）を学びたい学生
- 6502 CPUやレトロコンピューティングに興味があるエンジニア
- コンピュータアーキテクチャを基礎から深く理解したいホビーユーザー

## Project Goals

- 6502 CPUをSystemVerilogで完全に実装し、Tang Nano 9K/20K上で動作させる。
- FPGAの基本的な開発フロー（設計、シミュレーション、論理合成、実機検証）を習得する。
- 8bit CPUの実装を通じて、レジスタ、ALU、デコーダ、メモリマップドI/Oなどのコンピュータアーキテクチャの核心を理解する。
- 最終的にWoz Monitorなどの実用的なソフトウェアが動作するシステムを構築する。

## Key Features

- **Step-by-Step Curriculum:** Day01からDay99まで、難易度が段階的に上がる学習コンテンツ。
- **Hardware-Native Debugger:** CPUの内部状態をLCDにリアルタイム表示し、視覚的なデバッグを可能にする。
- **Reference Implementations:** 各ステップごとに「完成版」のソースコードを提供し、学習の躓きを防止。
- **Dual Platform Support:** Tang Nano 9Kおよび20Kの両方に対応したプロジェクト構成。

## Success Outcomes

- 低レイヤー（CPU、メモリ、周辺機器）の動作原理に関する深い知識。
- SystemVerilogを用いた実践的なデジタル回路設計スキル。
- 自らCPUをゼロから構築したという成功体験と、さらなるハードウェア開発への自信。

## Quality Guidelines

- **Reproducibility:** 誰でもREADMEに従えば環境構築から実行まで行えること。
- **Comprehensive Docs:** 各回路の意図や設計思想が明文化されていること。
- **Simulation First:** 実機に書き込む前に、シミュレーションで正しさを検証する習慣を促進する。
