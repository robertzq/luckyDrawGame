# Lucky Draw Game 🎲

基于 **Godot 4.5.1** 引擎开发的一款物理引擎抽奖模拟器。
本项目通过模拟真实世界中抽奖机的空气动力学和刚体物理碰撞，来实现完全随机、视觉效果生动的摇号过程。

## ✨ 核心机制 (Core Mechanics)

游戏的核心逻辑完全依赖于 Godot 的物理引擎 (`RigidBody2D` / `RigidBody3D`)，没有使用伪随机数直接决定结果，而是通过“气流”与“小球”的物理交互来产生结果：

* **🟢 刚体小球 (Rigid Body Balls):** 每一个抽奖球都是一个独立的刚体，具有质量、弹性和摩擦力。
* **🌬️ 三向扰乱气流 (Directional Airflows):** 抽奖盒内部设置了三个方向的持续力场（恒定推力/风力）：
    * **左侧气流：** 将小球向右侧吹动。
    * **右侧气流：** 将小球向左侧吹动。
    * **底部气流：** 强大的上升气流，将堆积在底部的小球向上吹起，确保所有小球处于无规则的混沌运动状态。

## 🛠️ 开发环境 (Environment)

* **Game Engine:** [Godot Engine](https://godotengine.org/) v4.5.1
* **Language:** GDScript

## 🚀 快速开始 (Getting Started)

如果你想在本地运行或修改这个项目，请按照以下步骤操作：

1. **克隆仓库到本地:**
   ```bash
   git clone [https://github.com/robertzq/luckyDrawGame.git](https://github.com/robertzq/luckyDrawGame.git)