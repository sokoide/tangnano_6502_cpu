# Product Guidelines - 6502 CPU on FPGA Learning Journey

## Documentation and Tone

- **Technical & Objective:** 教育資料としての正確性を担保するため、正確な専門用語を使用し、客観的な記述を心がけます。
- **Friendly & Educational:** 学習者が挫折しないよう、難しい概念は丁寧に解説し、図解や例え話を活用します。
- **Bilingual Support:** 重要なコンセプトやREADMEは日本語と英語の両方で提供し、幅広いユーザーが利用できるようにします。

## Code Quality (SystemVerilog)

- **Readability and Consistency:** コード自体が教材となるため、命名規則（スネークケース、プレフィックスの活用など）を統一し、インデントやコメントを適切に配置します。
- **Modularity:** ALU、レジスタファイル、命令デコーダなどを独立したモジュールとして設計し、ハードウェア設計の基本である「コンポーネントの組み合わせ」を実践します。

## Educational Approach

- **Incremental Complexity:** Day01から段階的に難易度を上げ、一つ一つの機能を積み上げていくことで、学習者が常に「次に進める」感覚を持てるようにします。
- **Explain the "Why":** 単にコードを提示するだけでなく、その設計がなぜ必要なのか、どのようなトレードオフがあるのかという背景（Rationale）を詳しく説明します。
- **Hands-on Exercises:** 各ステップに演習問題を設け、ユーザーが自ら考え、コードを記述する機会を提供することで、知識の定着を促します。
- **Clear Pass Criteria:** 各 Day にロジックテスト用のテストベンチを提供し、シミュレーションで `PASS` を確認することを「その日のゴール」と定義することで、達成感を明確にします。

## Visual and User Experience (Debugger)

- **Information Organization:** LCDデバッグ画面では、レジスタ(A, X, Y, S, P)、プログラムカウンタ(PC)、現在実行中の命令、バスの状態などを整理して配置し、一目でCPUの状態を把握できるようにします。
- **Simplicity & Functionality:** 派手なUIよりも、デバッグに必要な情報が正確かつ迅速に伝わる、機能的なインターフェースを優先します。

## Verification Guidelines

- **Testbench First:** 主要なモジュールには必ずSystemVerilog of the testbenchを用意し、論理的な正しさをシミュレーションで担保する手順を徹底します。
- **Timing Analysis:** 波形解析ツール（GTKWaveなど）を用いたデバッグ手順を解説し、ハードウェア特有の「タイミング」という概念を視覚的に理解できるようにします。
