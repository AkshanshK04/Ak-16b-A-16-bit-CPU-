program_file = "program.hex"

# ===================== Load Program =====================
with open(program_file, "r") as f:
    lines = [line.strip() for line in f.readlines() if line.strip()]
instructions = [line.zfill(4) for line in lines]

# ===================== Config =====================
REG_COUNT = 16
MEM_COUNT = 16
STEP = 10
NOP = "0000"

registers = [0] * REG_COUNT
memory = [0] * MEM_COUNT

pipeline = {
    "IF":  {"instr": NOP},
    "ID":  {"instr": NOP},
    "EX":  {"instr": NOP},
    "MEM": {"instr": NOP},
    "WB":  {"instr": NOP},
}

pc = 0
time = 0
halted = False

# ===================== Helper Functions =====================
def decode(instr):
    if not instr or instr == NOP:
        return None, None, None, None
    op = int(instr[0], 16)
    rd = int(instr[1], 16)
    rs1 = int(instr[2], 16)
    rs2 = int(instr[3], 16)
    return op, rd, rs1, rs2

def execute(op, rs1_val, rs2_val):
    if op == 1:      # ADD
        return (rs1_val + rs2_val) & 0xFFFF
    elif op == 2:    # SUB
        return (rs1_val - rs2_val) & 0xFFFF
    elif op == 3:    # AND
        return rs1_val & rs2_val
    elif op == 4:    # OR
        return rs1_val | rs2_val
    elif op == 5:    # LW
        return memory[rs2_val % MEM_COUNT]
    elif op == 6:    # SW
        memory[rs2_val % MEM_COUNT] = rs1_val
        return None
    elif op == 7:    # JUMP
        return rs2_val
    elif op == 12:   # BEQ
        return 1 if rs1_val == rs2_val else 0
    elif op == 13:   # BNE
        return 1 if rs1_val != rs2_val else 0
    elif op == 15:   # HALT
        return None
    else:
        return 0

def hazard_stall(id_instr, ex_stage):
    if not id_instr or id_instr == NOP:
        return False
    id_op, id_rd, id_rs1, id_rs2 = decode(id_instr)
    
    ex_instr = ex_stage.get("instr") if isinstance(ex_stage, dict) else ex_stage
    if not ex_instr or ex_instr == NOP:
        return False
    ex_op, ex_rd, _, _ = decode(ex_instr)
    if ex_op == 5 and ex_rd in (id_rs1, id_rs2) and ex_rd != 0:
        return True
    return False

def forward_val(rs):
    mem_stage = pipeline['MEM']
    if mem_stage and mem_stage.get('rd') == rs and mem_stage.get('alu_res') is not None and rs != 0:
        return mem_stage['alu_res']
    wb_stage = pipeline['WB']
    if wb_stage and wb_stage.get('rd') == rs and wb_stage.get('alu_res') is not None and rs != 0:
        return wb_stage['alu_res']
    return registers[rs]

def print_snapshot(time, pc):
    ex_rd = pipeline['EX'].get('rd', 0)
    wb_rd = pipeline['WB'].get('rd', 0)
    wb_w  = 1 if pipeline['WB'].get('rd', 0) != 0 else 0
    id_instr = pipeline['ID'].get('instr', NOP)
    if_instr = pipeline['IF'].get('instr', NOP)
    print(f"T={time:<7} | IF_PC={pc:04x} | IF_INSTR={if_instr} | ID_INSTR={id_instr} | EX_RD={ex_rd} | WB_RD={wb_rd} | WB_W={wb_w}")

def print_registers():
    print("\n=== REGISTER FILE ===")
    for i, val in enumerate(registers):
        print(f"R{i} = {val:04x} ({val})")
    print("\n=== DATA MEMORY [0..7] ===")
    for i in range(8):
        print(f"mem[{i}] = {memory[i]:04x}")

# ===================== Simulation Loop =====================
while not halted:
    time += STEP

    # -------- WB Stage --------
    wb_stage = pipeline['WB']
    if wb_stage and wb_stage.get('rd', 0) != 0 and wb_stage.get('alu_res') is not None:
        registers[wb_stage['rd']] = wb_stage['alu_res']

    # -------- MEM -> WB --------
    pipeline['WB'] = pipeline['MEM']

    # -------- EX Stage --------
    ex_stage = pipeline['EX']
    if ex_stage:
        instr = ex_stage.get('instr', NOP)
        op, rd, rs1, rs2 = decode(instr)
        rs1_val = forward_val(rs1) if rs1 is not None else 0
        rs2_val = forward_val(rs2) if rs2 is not None else 0
        alu_res = execute(op, rs1_val, rs2_val)
        pipeline['EX']['alu_res'] = alu_res
        pipeline['EX']['rd'] = rd

        # HALT
        if op == 15:
            halted = True

        # JUMP / BRANCH
        if op == 7:  # JUMP
            pc = alu_res
            pipeline['IF'] = {"instr": NOP}
            pipeline['ID'] = {"instr": NOP}
        elif op in (12, 13) and alu_res == 1:  # BEQ/BNE taken
            pc = pc + 1
            pipeline['IF'] = {"instr": NOP}
            pipeline['ID'] = {"instr": NOP}

    # -------- Hazard Detection --------
    stall = hazard_stall(pipeline['ID'].get('instr'), pipeline['EX'])

    # -------- IF/ID/EX Shift --------
    if not stall:
        pipeline['MEM'] = pipeline['EX']
        pipeline['EX']  = pipeline['ID']
        if pc < len(instructions):
            pipeline['ID'] = {"instr": instructions[pc]}
            pipeline['IF'] = {"instr": instructions[pc]}
        else:
            pipeline['ID'] = {"instr": NOP}
            pipeline['IF'] = {"instr": NOP}
        pc += 1
    else:
        # Stall: insert NOP in EX
        pipeline['MEM'] = pipeline['EX']
        pipeline['EX'] = {"instr": NOP}

    # -------- Print Snapshot --------
    print_snapshot(time, pc)

# -------- Final Registers --------
print_registers()
