# SampleCPU Vivado 仿真运行指南

## 一、前期准备

### 1.1 环境要求
- **Vivado版本**：推荐 2018.3 或更高版本
- **操作系统**：Windows 10/11 或 Linux
- **硬件配置**：
  - 内存：至少 8GB RAM（推荐 16GB）
  - 硬盘空间：至少 30GB 可用空间
  - CPU：多核处理器（首次综合IP核需要较长时间）

### 1.2 下载实验平台
1. 从群文件下载 `nscscc2021_group_v0.01.7z`
2. 解压密码：`nscscc2021`
3. 解压到本地目录（建议路径不含中文和空格）
   - 例如：`D:\nscscc2021_group_v0.01\`

### 1.3 准备CPU源码
1. 确保已clone或下载本项目到本地
2. 记录项目路径，例如：`C:\Users\19595\Desktop\computer_system-main\SampleCPU-main`

---

## 二、创建/打开Vivado项目

### 2.1 方式一：使用现有项目（推荐）

#### 步骤1：启动Vivado项目
1. 导航到解压后的实验平台路径：
   ```
   nscscc2021_group_v0.01\func_test_v0.01\soc_sram_func\run_vivado\mycpu_prj1\
   ```

2. 双击打开 `mycpu.xpr` 文件
   - Vivado会自动启动并加载项目
   - 如果提示路径不匹配，选择"确定"或"更新路径"

#### 步骤2：项目结构说明
打开后会看到以下主要目录结构：
- **Design Sources**：设计源文件
- **Constraints**：约束文件
- **Simulation Sources**：仿真文件
  - `sim_1` → `tb` → `mycpu_tb.v`（测试平台）

### 2.2 方式二：从零创建新项目

#### 步骤1：启动Vivado
1. 打开Vivado软件
2. 点击 `Create Project` 或 `File` → `Project` → `New`

#### 步骤2：项目基本设置
1. **Project name**：输入项目名称，如 `mycpu_project`
2. **Project location**：选择项目存放路径（不含中文）
3. 勾选 `Create project subdirectory`
4. 点击 `Next`

#### 步骤3：项目类型
1. 选择 `RTL Project`
2. 勾选 `Do not specify sources at this time`
3. 点击 `Next`

#### 步骤4：选择开发板
1. 在 `Parts` 选项卡中选择芯片型号
   - 龙芯平台常用：`xc7a200tfbg676-2`（Artix-7系列）
2. 或者在 `Boards` 选项卡选择对应开发板
3. 点击 `Next` → `Finish`

---

## 三、添加源文件

### 3.1 添加设计源文件

#### 方法一：通过GUI添加
1. 在左侧 `Project Manager` 面板，点击 `Add Sources`
2. 或点击 `Flow Navigator` → `Project Manager` → `Add Sources`

#### 步骤详解：
1. 选择 `Add or create design sources`，点击 `Next`

2. 点击 `Add Files` 按钮

3. 导航到SampleCPU项目目录，按照以下顺序添加文件：

   **顶层文件：**
   - `mycpu_top.v`
   - `mycpu_core.v`

   **流水段模块：**
   - `IF.v`
   - `ID.v`
   - `EX.v`
   - `MEM.v`
   - `WB.v`
   - `CTRL.v`

   **乘法器模块（可选，使用自定义乘法器时）：**
   - `mymul.v`

   **lib文件夹中的文件：**
   - `lib/defines.vh`
   - `lib/alu.v`
   - `lib/regfile.v`
   - `lib/mmu.v`
   - `lib/div.v`
   - `lib/decoder_5_32.v`
   - `lib/decoder_6_64.v`

   **lib/mul文件夹中的文件（如使用Wallace乘法器）：**
   - `lib/mul/mul.v`
   - `lib/mul/add.v`
   - `lib/mul/fa.v`

4. **重要**：添加完成后，点击 `Finish`

#### 方法二：通过TCL命令添加（快速）
在Vivado的 TCL Console 中执行：
```tcl
# 设置源文件路径
set src_path "C:/Users/19595/Desktop/computer_system-main/SampleCPU-main"

# 添加设计源文件
add_files -fileset sources_1 [list \
    "$src_path/mycpu_top.v" \
    "$src_path/mycpu_core.v" \
    "$src_path/IF.v" \
    "$src_path/ID.v" \
    "$src_path/EX.v" \
    "$src_path/MEM.v" \
    "$src_path/WB.v" \
    "$src_path/CTRL.v" \
    "$src_path/mymul.v" \
    "$src_path/lib/defines.vh" \
    "$src_path/lib/alu.v" \
    "$src_path/lib/regfile.v" \
    "$src_path/lib/mmu.v" \
    "$src_path/lib/div.v" \
    "$src_path/lib/decoder_5_32.v" \
    "$src_path/lib/decoder_6_64.v" \
]

# 设置顶层模块
set_property top mycpu_top [current_fileset]

# 更新编译顺序
update_compile_order -fileset sources_1
```

### 3.2 设置顶层模块
1. 在 `Sources` 窗口中，右键点击 `mycpu_top.v`
2. 选择 `Set as Top`
3. 顶层模块图标会变成三角形标记

### 3.3 检查文件层次
1. 点击 `Hierarchy` 选项卡
2. 确认 `mycpu_top` 在最顶层
3. 展开查看各模块实例化关系

---

## 四、配置仿真设置

### 4.1 添加仿真测试文件
如果使用龙芯平台：
1. 测试平台文件 `mycpu_tb.v` 已在龙芯项目中
2. 通常位于：
   ```
   nscscc2021_group_v0.01\func_test_v0.01\soc_sram_func\rtl\
   ```

### 4.2 设置仿真参数
1. 点击 `Simulation` → `Simulation Settings`
2. 或 `Flow Navigator` → `Simulation` → `Settings`

#### 关键设置项：
- **Simulation top module**：确认为 `mycpu_tb`（测试平台）
- **Simulation Run Time**：设置为 `-all` 或足够长的时间（如 `100ms`）
- **xsim.simulate.runtime**：根据测试规模设置
- **xsim.simulate.log_all_signals**：勾选以记录所有信号

### 4.3 配置编译选项
1. `Settings` → `Simulation` → `Compilation`
2. 添加 include 路径（如果需要）：
   - `-i` 指向 `lib` 目录的路径

---

## 五、运行仿真

### 5.1 首次仿真（综合IP核）

#### 步骤1：启动仿真
1. 点击 `Flow Navigator` → `Simulation` → `Run Simulation` → `Run Behavioral Simulation`
2. 或快捷方式：`Ctrl + F11`

#### 步骤2：等待综合
**重要提示**：
- 首次运行需要综合龙芯平台的IP核
- 这个过程可能需要 **10-25分钟**（取决于电脑性能）
- 进度显示在Vivado右上角的状态栏
- 请耐心等待，**不要中断**

#### 观察过程：
- TCL Console会显示编译进度
- 可能看到：
  ```
  Compiling module...
  Elaborating...
  Generating IP...
  ```

### 5.2 观察仿真界面

#### 仿真启动后的界面布局：
1. **左上 - Scope窗口**：显示设计层次结构
2. **左下 - Objects窗口**：显示当前模块的信号
3. **右侧 - Waveform窗口**：波形显示区域
4. **底部 - TCL Console**：显示仿真信息和错误

### 5.3 添加观察信号

#### 自动添加所有信号：
1. 在 `Scope` 窗口选择需要观察的模块（如 `mycpu_top`）
2. 右键 → `Add to Wave Window` → `All signals in selected scope`

#### 手动添加关键信号：
建议添加以下信号便于调试：

**顶层信号：**
- `clk`, `resetn`
- `debug_wb_pc`（当前写回的PC）
- `debug_wb_rf_wen`（寄存器写使能）
- `debug_wb_rf_wnum`（写入的寄存器号）
- `debug_wb_rf_wdata`（写入的数据）

**指令与数据接口：**
- `inst_sram_addr`（取指地址）
- `inst_sram_rdata`（取到的指令）
- `data_sram_addr`（访存地址）
- `data_sram_wdata`（写入的数据）
- `data_sram_rdata`（读取的数据）

**流水段信号：**
- `u_mycpu_core/u_IF/pc_reg`
- `u_mycpu_core/u_ID/inst`
- `u_mycpu_core/u_EX/ex_result`
- `u_mycpu_core/stall`（暂停信号）

### 5.4 运行仿真

#### 方法一：持续运行
1. 点击工具栏的 **播放按钮** （Run All）
2. 或按 `F3` 快捷键
3. 仿真会一直运行直到：
   - 遇到 `$finish` 或 `$stop`
   - 触发断点
   - 手动暂停

#### 方法二：单步运行
1. 设置时间步长：在工具栏输入框输入时间（如 `100ns`）
2. 点击 **Run for** 按钮（或 `F2`）
3. 仿真会运行指定时间后暂停

#### 控制按钮说明：
- **Run All (F3)**：持续运行
- **Run For (F2)**：运行指定时间
- **Step (F5)**：单步执行
- **Break (F6)**：暂停仿真
- **Restart (F7)**：重启仿真

---

## 六、观察和分析结果

### 6.0 仿真结果查看位置与界面说明

#### 仿真成功启动后，你会看到：

**1. 主界面布局**
```
┌─────────────────────────────────────────────────────────┐
│  Vivado Simulator                            [工具栏]    │
├──────────────┬──────────────────────────────────────────┤
│  Scope       │                                          │
│  (层次结构)   │         Waveform Window                  │
│              │         (波形显示区域)                     │
│──────────────│                                          │
│  Objects     │                                          │
│  (信号列表)   │                                          │
├──────────────┴──────────────────────────────────────────┤
│  Tcl Console (控制台输出 - 最重要!)                       │
│  >>> 这里显示仿真运行信息和trace比对结果                   │
└─────────────────────────────────────────────────────────┘
```

**2. 三个关键显示区域**

#### 📺 区域一：TCL Console（底部窗口）- 主要结果输出
**位置**：Vivado窗口最底部的黑色/深色控制台
**作用**：显示仿真过程的所有文本信息

**成功运行时会看到：**
```tcl
INFO: [USF-XSim-96] XSim completed. Design snapshot 'mycpu_top_behav' loaded.
INFO: [USF-XSim-97] XSim simulation ran for 1000ns
```

**如果使用龙芯测试平台，还会实时显示：**
- 每条指令的PC值和指令码
- 寄存器写回信息
- 错误比对提示（如果有）

#### 📊 区域二：Waveform Window（右侧大窗口）- 波形显示
**位置**：界面右侧或中央大面积区域
**作用**：图形化显示所有信号随时间的变化

**如何查看：**
1. 横轴是时间（单位：ns、us、ms）
2. 纵轴是各个信号的名称
3. 信号值以波形形式显示（高低电平、数字值）
4. **需要手动添加信号才会显示**（见5.3节）

**查看方法：**
- 用鼠标拖动时间轴查看不同时刻
- 点击信号可在Objects窗口看到数值
- 右键信号可更改显示格式（十六进制/二进制/十进制）

#### 🗂️ 区域三：Objects Window（左下）- 当前信号值
**位置**：左侧下方窗口
**作用**：显示当前光标所在时刻，所选模块的所有信号及其数值

**使用方法：**
1. 在Scope窗口选择模块（如`mycpu_top`）
2. Objects窗口会列出该模块所有信号
3. 光标在波形上移动时，这里的值会实时更新

---

### 6.1 如何判断仿真是否运行成功

#### ✅ 成功的标志：

**TCL Console显示：**
```tcl
INFO: [USF-XSim-96] XSim completed. Design snapshot 'mycpu_top_behav' loaded.
INFO: [USF-XSim-97] XSim simulation ran for 1000ns
launch_simulation: Time (s): cpu = 00:00:04 ; elapsed = 00:00:15
```
- 看到 "XSim completed" 表示仿真环境启动成功
- 看到 "simulation ran for XXXns" 表示已运行指定时间
- 没有 "ERROR" 字样

**Waveform窗口：**
- 如果添加了信号，应该能看到波形
- 时间轴显示 0ns 到 1000ns（或你设置的时间）
- 信号有变化（不全是X或Z）

#### ❌ 失败的标志：

**TCL Console显示ERROR：**
```tcl
ERROR: [VRFC 10-91] syntax error near XXX
ERROR: [Vivado 12-4473] Detected error while running simulation
```

**常见错误含义：**
- `syntax error`：语法错误，检查Verilog代码
- `undeclared identifier`：未声明的变量
- `Cannot find design unit`：找不到模块，检查文件是否添加

---

### 6.2 龙芯平台Trace比对机制详解

#### 比对信息输出位置：
仿真运行时，**TCL Console** 底部会实时输出比对信息：

**正常运行输出示例：**
```
[TEST] PC: 0xbfc00000, Inst: 0x3c1a8000
[TEST] PC: 0xbfc00004, Inst: 0x3c1bbfb0
...
```

**发现错误时输出示例：**
```
--------------------------ERROR!--------------------------
  Reference: PC = 0xbfc00100, wb_rf_wnum = 0x08, wb_rf_wdata = 0x12345678
       SoC:  PC = 0xbfc00100, wb_rf_wnum = 0x08, wb_rf_wdata = 0x00000000
Error: wb_rf_wdata mismatch!
----------------------------------------------------------
Testbench stopped at PC = 0xbfc00100
```

**如何理解trace输出：**
- `Reference`：标准参考答案（golden model）
- `SoC`：你的CPU实际输出
- `PC`：当前出错指令的地址
- `wb_rf_wnum`：写回的寄存器号（0x08 = $t0）
- `wb_rf_wdata`：写回的数据值
- 当两者不匹配时，仿真会自动停止

#### 无龙芯平台时如何查看结果

**如果是简单测试项目（无testbench比对）：**

1. **在Waveform中手动观察关键信号**
   - 添加 `debug_wb_pc`：查看程序运行流程
   - 添加 `debug_wb_rf_wdata`：查看写回数据
   - 添加 `inst_sram_rdata`：查看执行的指令
   
2. **验证方法：**
   ```verilog
   // 例如验证 ori $t0, $zero, 0x1234
   // 观察波形中：
   // - inst_sram_rdata 应为对应的机器码
   // - debug_wb_rf_wnum 应为 8 (对应$t0)
   // - debug_wb_rf_wdata 应为 0x1234
   ```

3. **在代码中添加监视器（Monitor）：**
   ```verilog
   // 在testbench中添加
   always @(posedge clk) begin
       if (u_mycpu_top.debug_wb_rf_wen == 4'b1111) begin
           $display("Time=%0t PC=%h Reg[%0d]=%h", 
                    $time, 
                    u_mycpu_top.debug_wb_pc,
                    u_mycpu_top.debug_wb_rf_wnum,
                    u_mycpu_top.debug_wb_rf_wdata);
       end
   end
   ```
   这会在TCL Console输出每次寄存器写入的信息

---

### 6.3 错误定位流程

#### 步骤1：记录错误PC
从TCL Console输出中找到出错的PC值，例如：`0xbfc00100`

#### 步骤2：查找对应汇编指令
1. 打开文件：
   ```
   nscscc2021_group_v0.01\func_test_v0.01\soft\func\obj\test.s
   ```
   **注意**：路径为 `soft/func/obj/test.s`（README中有更正说明）

2. 在文件中搜索PC值（去掉`0x`前缀）
   - 例如搜索：`bfc00100`

3. 找到对应的汇编指令，例如：
   ```assembly
   bfc00100:   01094021    addu    $t0, $t0, $t1
   ```

#### 步骤3：分析指令功能
1. 查阅 `doc` 文件夹中的 **A03 指令集文件**
2. 确认该指令的：
   - 操作码和功能码
   - 源寄存器和目的寄存器
   - 预期行为

#### 步骤4：波形分析
1. 在波形窗口找到错误PC对应的时间点
2. 暂停仿真（如果还在运行）
3. 添加相关信号到波形窗口：
   - ID段的译码信号
   - EX段的执行结果
   - 寄存器读写数据
   - 数据前递信号

4. 逐信号检查：
   - 指令是否被正确译码？
   - ALU输入是否正确？
   - 数据前递是否正确？
   - 写回数据是否正确？

### 6.4 使用波形调试

#### 查找特定时刻：
1. **按PC查找**：
   - 在波形窗口右键 → `Search`
   - 输入要查找的PC值
   - 设置搜索条件为 `debug_wb_pc == 0xbfc00100`

2. **使用光标跳转**：
   - 点击时间轴定位
   - 使用 `Ctrl + →/←` 移动到下一个/上一个边沿

#### 查看信号值：
1. **当前值**：左侧Objects窗口显示当前时刻的值
2. **历史值**：在波形上点击查看
3. **十六进制/二进制切换**：右键信号 → `Radix` → 选择显示格式

**技巧：同时对比多个信号**
```
在波形窗口中：
1. 选中一个时间点（竖线光标）
2. 可以同时看到所有信号在该时刻的值
3. 拖动光标，观察信号随时间的变化关系
```

**技巧：使用标尺测量时间间隔**
```
1. 在波形上右键 → "Add Marker"
2. 可以添加多个标记
3. 两个标记之间会显示时间差
4. 用于验证指令执行周期数
```

#### 添加标记：
1. 在波形上右键 → `Add Marker`
2. 可以标记关键时间点便于对比

#### 波形分组管理
```
1. 在波形窗口右键 → "New Group"
2. 创建分组如：
   - "流水线控制信号"
   - "IF段信号"
   - "数据通路"
3. 将相关信号拖入对应分组
4. 可以折叠/展开分组，便于查看
```

### 6.4 常见错误类型

#### 1. 指令未实现
**现象**：某个PC的指令执行结果全0或错误
**排查**：
- 检查ID段是否识别该指令（`inst_xxx` 信号）
- 检查ALU操作选择是否正确

#### 2. 数据相关未处理
**现象**：使用前一条指令结果的指令出错
**排查**：
- 检查 `ex_to_id/mem_to_id/wb_to_id` 前递路径
- 检查数据选择优先级

#### 3. Load-Use冒险
**现象**：load指令后紧跟使用该数据的指令出错
**排查**：
- 检查 `stallreq_from_id` 是否正确触发
- 检查 `stall` 信号是否正确插入空泡

#### 4. 分支/跳转错误
**现象**：PC跳转到错误地址
**排查**：
- 检查 `br_bus` 的分支条件判断
- 检查跳转目标地址计算
- 注意延迟槽的处理

#### 5. 访存字节选择错误
**现象**：`lb/lh/sb/sh` 指令数据错误
**排查**：
- 检查 `data_sram_wen` 的字节选择
- 检查MEM段的字节扩展逻辑
- 检查地址低两位 `addr[1:0]` 的使用

---

### 6.5 实战示例：如何从零开始查看结果

#### 场景：刚启动仿真，什么都看不到

**步骤1：确认仿真已启动**
```
查看TCL Console最后几行：
✅ 如果看到 "XSim completed" → 仿真环境OK
❌ 如果看到 "ERROR" → 先修复错误
```

**步骤2：添加基础观察信号**
```
1. 在左侧Scope窗口点击 "mycpu_top"
2. 在左下Objects窗口找到以下信号：
   - clk
   - resetn  
   - debug_wb_pc
   - debug_wb_rf_wen
   - debug_wb_rf_wdata
3. 按住Ctrl，多选这些信号
4. 右键 → "Add to Wave Window"
```

**步骤3：运行仿真产生数据**
```
1. 点击工具栏的播放按钮（Run All）或按F3
2. 或者输入时间后点击"Run for"
```

**步骤4：查看波形**
```
1. 在Waveform窗口，应该能看到添加的信号
2. 点击工具栏的 "Zoom Fit" (📐图标) 自动缩放
3. 用鼠标滚轮放大/缩小查看细节
```

**步骤5：分析结果**
```
查看 debug_wb_pc 信号：
- 是否从 0xbfbffffc 开始？
- 是否每个周期递增 4？（顺序执行时）
- 遇到分支指令是否正确跳转？

查看 debug_wb_rf_wen：
- 在需要写寄存器时是否为 4'b1111？
- 在不写寄存器时是否为 4'b0000？

查看 debug_wb_rf_wdata：
- 写入的数据是否符合预期？
- 可以在TCL Console用计算器验证
```

**步骤6：如果使用龙芯平台**
```
直接看TCL Console输出：
- 如果一直滚动显示[TEST]信息 → 正在正常运行
- 如果停止并显示ERROR → 定位到出错的PC
- 如果什么都不显示 → 检查testbench是否正确加载
```

---

### 6.6 快速诊断清单

遇到问题时，按此顺序检查：

**□ 仿真启动检查**
- [ ] TCL Console有"XSim completed"提示
- [ ] 没有红色ERROR信息
- [ ] Waveform窗口已打开

**□ 信号显示检查**
- [ ] 已添加信号到波形窗口
- [ ] 时间轴不是0ns（说明已运行）
- [ ] 信号不全是X或Z（说明有驱动）

**□ 时钟复位检查**
- [ ] clk信号正常翻转（方波）
- [ ] resetn在开始时为0，之后变为1
- [ ] PC在复位后正确初始化

**□ 功能检查**
- [ ] PC按预期递增或跳转
- [ ] 寄存器写使能在正确时刻有效
- [ ] 写回数据与手工计算一致

**□ 龙芯平台检查（如果使用）**
- [ ] TCL Console有trace输出
- [ ] Reference和SoC的值相同
- [ ] 没有ERROR提示
如果只调试前几条指令：
1. 在testbench中添加：
   ```verilog
   initial begin
       #10000000;  // 10ms后停止
       $finish;
   end
   ```

#### 方法2：减少波形记录
1. 只添加必要的信号到波形窗口
2. `Settings` → 取消勾选 `Log all signals`

#### 方法3：使用检查点
1. 运行到关键位置后保存检查点：
   - `Simulation` → `Save Checkpoint`
2. 下次可以从检查点恢复：
   - `Simulation` → `Open Checkpoint`

### 7.2 使用断点

#### 设置断点：
1. 在代码编辑器中，在行号处右键
2. 选择 `Toggle Breakpoint`
3. 或使用TCL命令：
   ```tcl
   add_bp -scope /mycpu_tb/u_mycpu_top -file mycpu_core.v -line 50
   ```

#### 条件断点：
在TCL Console中：
```tcl
run 1000ns
when {debug_wb_pc == 32'hbfc00100} {
    stop
}
run -all
```

---

## 八、综合与实现（可选）

如果需要上板测试：

### 8.1 运行综合
1. `Flow Navigator` → `Synthesis` → `Run Synthesis`
2. 等待综合完成（可能需要几分钟）
3. 查看综合报告了解资源使用情况

### 8.2 运行实现
1. `Flow Navigator` → `Implementation` → `Run Implementation`
2. 等待布局布线完成
3. 查看时序报告确认时序收敛

### 8.3 生成比特流
1. `Flow Navigator` → `Program and Debug` → `Generate Bitstream`
2. 生成 `.bit` 文件用于FPGA烧写

---

## 九、常见问题FAQ

### Q1: Vivado打开项目报错"找不到源文件"？
**A**: 
- 检查源文件路径是否正确
- 如果路径变化，重新添加源文件
- 或修改 `.xpr` 文件中的路径

### Q2: 仿真一直卡在"Compiling"状态？
**A**: 
- 首次运行需要综合IP，耐心等待
- 检查TCL Console是否有错误信息
- 如果超过30分钟，可能是电脑配置不足

### Q3: 波形窗口没有信号显示？
**A**: 
- 确认已添加信号到波形窗口
- 点击工具栏的 `Zoom Fit` 调整时间范围
- 检查仿真是否已运行

### Q4: 提示"0000aaaa"的访存结果错误？
**A**: 
- 这是README中提到的已知问题
- 联系助教获取解决方案

### Q5: 除法器运行32周期后仍然stall？
**A**: 
- 检查 `stallreq_from_ex` 的释放条件
- 确认 `div_ready_i` 信号正确返回
- 查看 `stall` 总线是否正确更新

### Q6: 自定义乘法器不加分？
**A**: 
- 不能直接使用 `*` 运算符
- 需要实现移位加法或其他算法
- 提供说明文档

### Q7: 仿真结果正确，但TCL Console一直输出？
**A**: 
- 正常现象，trace机制会持续输出
- 可以手动点击 `Break` 停止
- 或在testbench中添加 `$finish`

---

## 十、进阶技巧

### 10.1 使用TCL脚本自动化

创建 `run_sim.tcl` 文件：
```tcl
# 打开项目
open_project mycpu.xpr

# 更新编译顺序
update_compile_order -fileset sources_1

# 启动仿真
launch_simulation

# 运行仿真
run 1ms

# 保存波形
save_wave_config mycpu_waveform.wcfg

# 关闭
close_sim
```

运行脚本：
```bash
vivado -mode tcl -source run_sim.tcl
```

### 10.2 批量测试

编写多个测试用例，使用脚本循环运行仿真并检查结果。

### 10.3 波形配置保存

1. 设置好信号和分组后
2. `File` → `Simulation Waveform` → `Save Configuration As`
3. 保存为 `.wcfg` 文件
4. 下次加载：`File` → `Simulation Waveform` → `Open Configuration`

---

## 十一、参考资料

- **龙芯平台文档**：`nscscc2021_group_v0.01\doc\`
- **指令集手册**：A03 文件
- **Vivado官方文档**：
  - UG973: Vivado Design Suite User Guide: Release Notes, Installation, and Licensing
  - UG900: Vivado Design Suite User Guide: Logic Simulation

---

## 附录：快捷键表

| 功能 | 快捷键 |
|------|--------|
| 运行仿真 | Ctrl + F11 |
| 运行所有 | F3 |
| 运行指定时间 | F2 |
| 单步执行 | F5 |
| 暂停 | F6 |
| 重启仿真 | F7 |
| 缩放适配 | Shift + F |
| 放大 | Ctrl + = |
| 缩小 | Ctrl + - |

---

## 更新日志

- **2025-12-22**：初始版本，覆盖完整的Vivado仿真流程

---

如有问题，请参考README.md或联系助教。
