program_file = "program.hex"

# ===================== Load Program =====================
with open(program_file, "r") as f:
    lines = [line.strip() for line in f.readlines() if line.strip()]
instructions = [line.zfill(4) for line in lines]

# ===================== Config =====================
REG_COUNT = 16
MEM_COUNT = 256
STEP = 10
NOP = "0000"

registers = [0] * REG_COUNT
memory = [0] * MEM_COUNT

# 6-stage pipeline: IF -> ID -> EX1 -> EX2 -> MEM -> WB
pipeline = {
    "IF":  {"instr": NOP, "pc": 0},
    "ID":  {"instr": NOP, "pc": 0},
    "EX1": {"instr": NOP, "pc": 0},
    "EX2": {"instr": NOP, "pc": 0},
    "MEM": {"instr": NOP, "pc": 0},
    "WB":  {"instr": NOP, "pc": 0},
}

pc = 0
time = 0
halted = False
cycle_count = 0
max_cycles = 10000

# ===================== Helper Functions =====================
def decode(instr):
    if not instr or instr == NOP:
        return None, None, None, None
    op = int(instr[0], 16)
    rd = int(instr[1], 16)
    rs1 = int(instr[2], 16)
    rs2 = int(instr[3], 16)
    return op, rd, rs1, rs2

def sign_extend_4bit(val):
    """Sign extend 4-bit immediate to 16-bit"""
    if val & 0x8:  # Check if bit 3 is set (negative)
        return val | 0xFFF0
    return val

def execute(op, rs1_val, rs2_val, imm):
    if op == 0:      # ADD
        return (rs1_val + rs2_val) & 0xFFFF
    elif op == 1:    # SUB
        return (rs1_val - rs2_val) & 0xFFFF
    elif op == 2:    # AND
        return rs1_val & rs2_val
    elif op == 3:    # OR
        return rs1_val | rs2_val
    elif op == 4:    # XOR
        return rs1_val ^ rs2_val
    elif op == 5:    # SLT
        return 1 if rs1_val < rs2_val else 0
    elif op == 6:    # ADDI
        return (rs1_val + imm) & 0xFFFF
    elif op == 7:    # ANDI
        return rs1_val & imm
    elif op == 8:    # ORI
        return rs1_val | imm
    elif op == 9:    # XORI
        return rs1_val ^ imm
    elif op == 10:   # LW - compute address only
        return (rs1_val + imm) & 0xFFFF
    elif op == 11:   # SW - compute address only
        return (rs1_val + imm) & 0xFFFF
    elif op == 12:   # BEQ
        return 1 if rs1_val == rs2_val else 0
    elif op == 13:   # BNE
        return 1 if rs1_val != rs2_val else 0
    elif op == 14:   # JUMP
        return imm & 0xFFFF
    elif op == 15:   # HALT
        return None
    else:
        return 0

def hazard_stall(id_instr, ex1_stage):
    """Check for load-use hazard"""
    if not id_instr or id_instr == NOP:
        return False
    id_op, id_rd, id_rs1, id_rs2 = decode(id_instr)
    
    ex1_instr = ex1_stage.get("instr")
    if not ex1_instr or ex1_instr == NOP:
        return False
    ex1_op, ex1_rd, _, _ = decode(ex1_instr)
    
    # Load instruction in EX1, check if ID needs that register
    if ex1_op == 10 and ex1_rd != 0:  # LW instruction
        if ex1_rd == id_rs1 or ex1_rd == id_rs2:
            return True
    return False

def forward_val(rs):
    """Get forwarded value for register rs"""
    if rs is None or rs == 0:
        return 0
    
    # Priority: EX2 > MEM > WB > Register File
    
    # Forward from EX2 stage (most recent)
    ex2_stage = pipeline['EX2']
    if ex2_stage.get('rd') == rs and ex2_stage.get('alu_res') is not None:
        ex2_op, _, _, _ = decode(ex2_stage.get('instr', NOP))
        if ex2_op not in [11, 15]:  # Not SW or HALT
            return ex2_stage['alu_res']
    
    # Forward from MEM stage
    mem_stage = pipeline['MEM']
    if mem_stage.get('rd') == rs:
        mem_op, _, _, _ = decode(mem_stage.get('instr', NOP))
        if mem_op == 10:  # LW - forward memory data
            return mem_stage.get('mem_data', 0)
        elif mem_op not in [11, 15] and mem_stage.get('alu_res') is not None:
            return mem_stage['alu_res']
    
    # Forward from WB stage
    wb_stage = pipeline['WB']
    if wb_stage.get('rd') == rs and wb_stage.get('write_data') is not None:
        return wb_stage['write_data']
    
    return registers[rs]

def print_snapshot():
    ex1_rd = pipeline['EX1'].get('rd', 0)
    ex2_rd = pipeline['EX2'].get('rd', 0)
    mem_rd = pipeline['MEM'].get('rd', 0)
    wb_rd = pipeline['WB'].get('rd', 0)
    wb_w = 1 if pipeline['WB'].get('rd', 0) != 0 and pipeline['WB'].get('write_data') is not None else 0
    id_instr = pipeline['ID'].get('instr', NOP)
    if_instr = pipeline['IF'].get('instr', NOP)
    mem_instr = pipeline['MEM'].get('instr', NOP)
    wb_instr = pipeline['WB'].get('instr', NOP)
    print(f"T={time:<7} | IF_PC={pc:04x} | IF={if_instr} | ID={id_instr} | EX1_RD={ex1_rd:x} | EX2_RD={ex2_rd:x} | MEM={mem_instr} MEM_RD={mem_rd:x} | WB={wb_instr} WB_RD={wb_rd:x} WB_W={wb_w}")

def print_registers():
    print("\n=== REGISTER FILE ===")
    for i, val in enumerate(registers):
        print(f"R{i:2d} = 0x{val:04x} ({val:6d})")
    print("\n=== DATA MEMORY [0..15] ===")
    for i in range(16):
        if i % 4 == 0:
            print()
        print(f"mem[{i:2d}]={memory[i]:04x} ", end="")
    print("\n")

# ===================== Simulation Loop =====================
print("=== AK-16 6-STAGE PIPELINE CPU SIMULATION START ===\n")

# Initialize IF stage with first instruction
if len(instructions) > 0:
    pipeline['IF'] = {'instr': instructions[0], 'pc': 0}

# Track if HALT was seen (but let pipeline drain)
halt_seen = False

while (not halt_seen or not all(pipeline[s].get('instr') == NOP for s in ['ID', 'EX1', 'EX2', 'MEM', 'WB'])) and cycle_count < max_cycles:
    time += STEP
    cycle_count += 1
    
    # ======== WB Stage ========
    wb_stage = pipeline['WB']
    if wb_stage.get('rd', 0) != 0 and wb_stage.get('write_data') is not None:
        op, _, _, _ = decode(wb_stage.get('instr', NOP))
        if op not in [11, 15]:  # Not SW or HALT
            registers[wb_stage['rd']] = wb_stage['write_data'] & 0xFFFF
    
    # ======== MEM Stage ========
    mem_stage = pipeline['MEM']
    write_data = None
    if mem_stage.get('instr') != NOP:
        op, rd, _, _ = decode(mem_stage['instr'])
        alu_res_mem = mem_stage.get('alu_res')
        
        if op == 10:  # LW
            if alu_res_mem is not None:
                addr = alu_res_mem & 0xFF
                mem_data = memory[addr]
                write_data = mem_data
                pipeline['MEM']['mem_data'] = mem_data
        elif op == 11:  # SW
            if alu_res_mem is not None:
                addr = alu_res_mem & 0xFF
                memory[addr] = mem_stage.get('rs2_val', 0) & 0xFFFF
            write_data = None
        elif op not in [12, 13, 14, 15]:  # Regular ALU ops
            write_data = alu_res_mem
        else:
            write_data = None
        pipeline['MEM']['write_data'] = write_data
    
    # ======== MEM -> WB ========
    pipeline['WB'] = {
        'instr': mem_stage.get('instr', NOP),
        'rd': mem_stage.get('rd', 0),
        'write_data': write_data,
        'pc': mem_stage.get('pc', 0)
    }
    
    # ======== EX2 -> MEM ========
    ex2_stage = pipeline['EX2']
    pipeline['MEM'] = {
        'instr': ex2_stage.get('instr', NOP),
        'rd': ex2_stage.get('rd', 0),
        'alu_res': ex2_stage.get('alu_res'),
        'rs2_val': ex2_stage.get('rs2_val', 0),
        'zero': ex2_stage.get('zero', 0),
        'branch_target': ex2_stage.get('branch_target', 0),
        'pc': ex2_stage.get('pc', 0)
    }
    
    # ======== EX1 Stage ========
    ex1_stage = pipeline['EX1']
    alu_res = None
    branch_taken = False
    jump_taken = False
    new_pc = None
    zero = 0
    
    if ex1_stage.get('instr') != NOP:
        instr = ex1_stage['instr']
        op, rd, rs1, rs2 = decode(instr)
        imm = sign_extend_4bit(rs2)
        
        # CRITICAL: Get fresh forwarded values in EX1 stage
        rs1_val = forward_val(ex1_stage.get('rs1', rs1))
        rs2_val = forward_val(ex1_stage.get('rs2', rs2))
        
        alu_res = execute(op, rs1_val, rs2_val, imm)
        zero = 1 if (alu_res is not None and alu_res == 0) else 0
        
        pipeline['EX1']['alu_res'] = alu_res
        pipeline['EX1']['rd'] = rd
        pipeline['EX1']['zero'] = zero
        pipeline['EX1']['rs2_val'] = rs2_val
        
        branch_target = (ex1_stage.get('pc', 0) + sign_extend_4bit(rd)) & 0xFFFF
        pipeline['EX1']['branch_target'] = branch_target
        
        # Handle control flow
        if op == 14:  # JUMP
            new_pc = imm
            jump_taken = True
        elif op == 15:  # HALT
            halt_seen = True
    
    # ======== EX1 -> EX2 ========
    # For SW: rd field actually contains rs2 (data register to store)
    ex1_rs2_val = ex1_stage.get('rs2_val', 0)
    if ex1_stage.get('instr') != NOP:
        op_ex1, rd_ex1, _, _ = decode(ex1_stage['instr'])
        if op_ex1 == 11:  # SW: rd field is actually rs2 (data to store)
            ex1_rs2_val = forward_val(rd_ex1)  # Forward the data value
    
    pipeline['EX2'] = {
        'instr': ex1_stage.get('instr', NOP),
        'rd': ex1_stage.get('rd', 0),
        'alu_res': alu_res,
        'rs2_val': ex1_rs2_val,
        'zero': zero,
        'branch_target': ex1_stage.get('branch_target', 0),
        'pc': ex1_stage.get('pc', 0)
    }
    
    # Check branch decision in EX2 (after this cycle)
    if pipeline['EX2'].get('instr') != NOP:
        op2, rd2, _, _ = decode(pipeline['EX2']['instr'])
        if op2 == 12 and pipeline['EX2'].get('zero') == 1:  # BEQ taken
            new_pc = pipeline['EX2'].get('branch_target', 0)
            branch_taken = True
        elif op2 == 13 and pipeline['EX2'].get('zero') == 0:  # BNE taken
            new_pc = pipeline['EX2'].get('branch_target', 0)
            branch_taken = True
    
    # ======== Hazard Detection ========
    stall = hazard_stall(pipeline['ID'].get('instr'), pipeline['EX1'])
    
    # Handle branch/jump flush
    if branch_taken or jump_taken:
        pipeline['IF'] = {'instr': NOP, 'pc': 0}
        pipeline['ID'] = {'instr': NOP, 'pc': 0}
        if new_pc is not None:
            pc = new_pc
    
    # ======== ID -> EX1 ========
    if not stall:
        id_stage = pipeline['ID']
        if id_stage.get('instr') != NOP:
            instr = id_stage['instr']
            op, rd, rs1, rs2 = decode(instr)
            
            # For SW, we need to read rs2 as data, not immediate
            rs1_val = forward_val(rs1)
            rs2_val = forward_val(rs2) if op == 11 else 0  # SW needs rs2 data
            
            pipeline['EX1'] = {
                'instr': instr,
                'rd': rd,
                'rs1': rs1,
                'rs2': rs2,
                'rs1_val': rs1_val,
                'rs2_val': rs2_val,
                'pc': id_stage.get('pc', 0)
            }
        else:
            pipeline['EX1'] = {'instr': NOP, 'pc': 0}
    else:
        # Insert bubble
        pipeline['EX1'] = {'instr': NOP, 'pc': 0}
    
    # ======== IF -> ID ========
    if not stall and not branch_taken and not jump_taken:
        pipeline['ID'] = {
            'instr': pipeline['IF'].get('instr', NOP),
            'pc': pipeline['IF'].get('pc', 0)
        }
        if not halt_seen:
            pc += 1
    elif stall:
        # Keep ID stage same (don't advance)
        pass
    
    # ======== IF Stage ========
    if not halt_seen and not stall:
        if pc < len(instructions):
            pipeline['IF'] = {'instr': instructions[pc], 'pc': pc}
        else:
            pipeline['IF'] = {'instr': NOP, 'pc': pc}
    
    # ======== Print Snapshot ========
    print_snapshot()

# ======== Final State ========
print(f"\n=== SIMULATION COMPLETE (cycles: {cycle_count}) ===")
print_registers()