program_file = "program.hex"

# Loading  Program
with open(program_file, "r") as f:
    lines = [line.strip() for line in f.readlines() if line.strip()]
instructions = [line.zfill(4) for line in lines]

# Config 
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

# Helper Functions 
def decode(instr):
    """Decode 16-bit instruction into opcode, rd, rs1, rs2"""
    if not instr or instr == NOP:
        return None, None, None, None
    op = int(instr[0], 16)
    rd = int(instr[1], 16)
    rs1 = int(instr[2], 16)
    rs2 = int(instr[3], 16)
    return op, rd, rs1, rs2

def sign_extend_4bit(val):
    """Treat 4-bit value as unsigned (0-15 range) for immediates"""
    return val & 0xF  # mask to 4 bits, no sign extension

def sign_extend_4bit_branch(val):
    """Sign extend 4-bit value for branch offsets (allows negative jumps)"""
    if val & 0x8:
        return (val | 0xFFF0) & 0xFFFF
    return val & 0xF

def to_signed(val):
    """Convert 16-bit unsigned to signed"""
    if val & 0x8000:
        return val - 0x10000
    return val

def execute(op, rs1_val, rs2_val, imm):
    """Execute ALU operation"""
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
        return 1 if to_signed(rs1_val) < to_signed(rs2_val) else 0
    elif op == 6:    # ADDI
        return (rs1_val + imm) & 0xFFFF
    elif op == 7:    # ANDI
        return rs1_val & (imm & 0xFFFF)
    elif op == 8:    # ORI
        return rs1_val | (imm & 0xFFFF)
    elif op == 9:    # XORI
        return rs1_val ^ (imm & 0xFFFF)
    elif op == 10:   # LW
        return (rs1_val + imm) & 0xFFFF
    elif op == 11:   # SW
        return (rs1_val + imm) & 0xFFFF
    elif op == 12:   # BEQ
        return (rs1_val - rs2_val) & 0xFFFF
    elif op == 13:   # BNE
        return (rs1_val - rs2_val) & 0xFFFF
    elif op == 14:   # JUMP
        return imm & 0xFFFF
    elif op == 15:   # HALT
        return None
    else:
        return 0

def hazard_stall(id_instr, ex1_stage):
    """Detect load-use hazard requiring stall"""
    if not id_instr or id_instr == NOP:
        return False
    id_op, id_rd, id_rs1, id_rs2 = decode(id_instr)
    
    ex1_instr = ex1_stage.get("instr")
    if not ex1_instr or ex1_instr == NOP:
        return False
    ex1_op, ex1_rd, _, _ = decode(ex1_instr)
    
    # Load instruction in EX1 creates hazard if ID needs that register
    if ex1_op == 10 and ex1_rd != 0:  # LW instruction
        if ex1_rd == id_rs1 or ex1_rd == id_rs2:
            return True
    return False

def forward_val(rs):
    """Get forwarded value for register with proper priority:
    EX2 (ALU only) > MEM (with load) > WB > Register File"""
    if rs is None or rs == 0:
        return 0
    
    # Priority 1: Forwarding from EX2 stage (ALU result only, NOT load)
    ex2_stage = pipeline['EX2']
    if ex2_stage.get('rd') == rs and ex2_stage.get('alu_res') is not None:
        ex2_instr = ex2_stage.get('instr', NOP)
        if ex2_instr != NOP:
            ex2_op, _, _, _ = decode(ex2_instr)
            # Only forward ALU results (load data not ready yet)
            if ex2_op not in [10, 11, 12, 13, 14, 15]:
                return ex2_stage['alu_res'] & 0xFFFF
    
    # Priority 2: Forwarding from MEM stage (including load data)
    mem_stage = pipeline['MEM']
    if mem_stage.get('rd') == rs:
        mem_instr = mem_stage.get('instr', NOP)
        if mem_instr != NOP:
            mem_op, _, _, _ = decode(mem_instr)
            if mem_op == 10:  # LW - forward memory data
                mem_data = mem_stage.get('mem_data')
                if mem_data is not None:
                    return mem_data & 0xFFFF
            elif mem_op not in [11, 12, 13, 14, 15]:  # Regular ALU ops
                alu_res = mem_stage.get('alu_res')
                if alu_res is not None:
                    return alu_res & 0xFFFF
    
    # Priority 3: Forwarding from WB stage
    wb_stage = pipeline['WB']
    if wb_stage.get('rd') == rs:
        write_data = wb_stage.get('write_data')
        if write_data is not None:
            return write_data & 0xFFFF
    
    # Priority 4: Use register file
    return registers[rs] & 0xFFFF

def print_snapshot():
    """Print current pipeline state"""
    ex1_rd = pipeline['EX1'].get('rd', 0)
    ex2_rd = pipeline['EX2'].get('rd', 0)
    mem_rd = pipeline['MEM'].get('rd', 0)
    wb_rd = pipeline['WB'].get('rd', 0)
    wb_w = 1 if pipeline['WB'].get('rd', 0) != 0 and pipeline['WB'].get('write_data') is not None else 0
    id_instr = pipeline['ID'].get('instr', NOP)
    if_instr = pipeline['IF'].get('instr', NOP)
    
    print(f"T={time:<7} | PC={pc:04x} | IF={if_instr} | ID={id_instr} | EX1_RD={ex1_rd:x} | EX2_RD={ex2_rd:x} | MEM_RD={mem_rd:x} | WB_RD={wb_rd:x} WB_W={wb_w}")

def print_registers():
    """Print final register and memory state"""
    print("\n=== REGISTER FILE ===")
    for i, val in enumerate(registers):
        print(f"R{i:2d} = 0x{val:04x} ({to_signed(val):6d})")
    print("\n=== DATA MEMORY [0..15] ===")
    for i in range(16):
        if i % 4 == 0:
            print()
        print(f"mem[{i:2d}]=0x{memory[i]:04x}  ", end="")
    print("\n")

# ===================== Simulation Loop =====================
print("=== AK-16 6-STAGE PIPELINE CPU SIMULATION ===")
print("=== Features: Forwarding, Stall, Flush, Branch, Jump ===\n")

# Initializing IF stage with first instruction
if len(instructions) > 0:
    pipeline['IF'] = {'instr': instructions[0], 'pc': 0}

halt_seen = False

while (not halt_seen or not all(pipeline[s].get('instr') == NOP for s in ['ID','EX1','EX2','MEM','WB'])) and cycle_count < max_cycles:
    time += STEP
    cycle_count += 1
    
    # WB Stage
    wb_stage = pipeline['WB']
    if wb_stage.get('rd', 0) != 0 and wb_stage.get('write_data') is not None:
        wb_instr = wb_stage.get('instr', NOP)
        if wb_instr != NOP:
            op, _, _, _ = decode(wb_instr)
            if op not in [11, 12, 13, 14, 15]:  # Not SW, BEQ, BNE, JUMP, HALT
                registers[wb_stage['rd']] = wb_stage['write_data'] & 0xFFFF
    
    # MEM Stage
    mem_stage = pipeline['MEM']
    write_data = None
    mem_data = None
    
    if mem_stage.get('instr') != NOP:
        op, rd, _, _ = decode(mem_stage['instr'])
        alu_res_mem = mem_stage.get('alu_res')
        
        if op == 10:  # LW
            if alu_res_mem is not None:
                addr = alu_res_mem & 0xFF
                mem_data = memory[addr] & 0xFFFF
                write_data = mem_data
                pipeline['MEM']['mem_data'] = mem_data
        elif op == 11:  # SW
            if alu_res_mem is not None:
                addr = alu_res_mem & 0xFF
                store_data = mem_stage.get('rs2_val', 0) & 0xFFFF
                memory[addr] = store_data
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
    
    # EX1 Stage 
    ex1_stage = pipeline['EX1']
    alu_res = None
    zero = 0
    branch_target = 0
    
    if ex1_stage.get('instr') != NOP:
        instr = ex1_stage['instr']
        op, rd, rs1, rs2 = decode(instr)
        imm = sign_extend_4bit(rs2)
        
        # Get forwarded values
        rs1_val = forward_val(ex1_stage.get('rs1', rs1))
        rs2_val = forward_val(ex1_stage.get('rs2', rs2))
        
        # Execute ALU operation
        alu_res = execute(op, rs1_val, rs2_val, imm)
        zero = 1 if (alu_res is not None and alu_res == 0) else 0
        
        # Calculate branch/jump target
        if op in [12, 13]:  # BEQ, BNE
            # Branch offset is in rd field (4-bit SIGNED for backward jumps)
            branch_offset = sign_extend_4bit_branch(rd)
            branch_target = ((ex1_stage.get('pc', 0) + 1) + branch_offset) & 0xFFFF
        elif op == 14:  # JUMP
            # JUMP uses 12-bit absolute address (rd, rs1, rs2 combined)
            jump_target = int(instr[1:], 16) & 0xFFF
            branch_target = jump_target
        
        pipeline['EX1']['alu_res'] = alu_res
        pipeline['EX1']['rd'] = rd
        pipeline['EX1']['zero'] = zero
        pipeline['EX1']['rs2_val'] = rs2_val
        pipeline['EX1']['branch_target'] = branch_target
        
        # Detect HALT
        if op == 15:
            halt_seen = True
    
    # ======== EX1 -> EX2 ========
    # For SW instruction, forward the actual data value
    ex1_rs2_val = ex1_stage.get('rs2_val', 0)
    if ex1_stage.get('instr') != NOP:
        op_ex1, rd_ex1, _, _ = decode(ex1_stage['instr'])
        if op_ex1 == 11:  # SW: rd field contains data register
            ex1_rs2_val = forward_val(rd_ex1)
    
    pipeline['EX2'] = {
        'instr': ex1_stage.get('instr', NOP),
        'rd': ex1_stage.get('rd', 0),
        'alu_res': alu_res,
        'rs2_val': ex1_rs2_val,
        'zero': zero,
        'branch_target': ex1_stage.get('branch_target', 0),
        'pc': ex1_stage.get('pc', 0)
    }
    
    #Control Flow Detection 
    jump_taken = False
    branch_taken = False
    new_pc = None
    
    # Check for JUMP in ID stage
    id_instr = pipeline['ID'].get('instr')
    if id_instr and id_instr != NOP:
        id_op, _, _, _ = decode(id_instr)
        if id_op == 14:  # JUMP
            # JUMP uses 12-bit absolute address
            new_pc = int(id_instr[1:], 16) & 0xFFF
            jump_taken = True
    
    # Check for branch in EX2 stage (if no jump)
    if not jump_taken:
        ex2_instr = pipeline['EX2'].get('instr')
        if ex2_instr and ex2_instr != NOP:
            op2, _, _, _ = decode(ex2_instr)
            ex2_zero = pipeline['EX2'].get('zero', 0)
            
            if op2 == 12 and ex2_zero == 1:  # BEQ and equal
                new_pc = pipeline['EX2']['branch_target']
                branch_taken = True
            elif op2 == 13 and ex2_zero == 0:  # BNE and not equal
                new_pc = pipeline['EX2']['branch_target']
                branch_taken = True
    
    # Pipeline Flush on Control Flow 
    if jump_taken or branch_taken:
        # Flush IF, ID, and EX1 stages
        pipeline['IF'] = {'instr': NOP, 'pc': 0}
        pipeline['ID'] = {'instr': NOP, 'pc': 0}
        pipeline['EX1'] = {'instr': NOP, 'pc': 0}
        if new_pc is not None:
            pc = new_pc
    
    # Hazard Detection
    stall = hazard_stall(pipeline['ID'].get('instr'), pipeline['EX1'])
    
    # ======== ID -> EX1 ========
    if not stall and not jump_taken:
        id_stage = pipeline['ID']
        if id_stage.get('instr') != NOP:
            instr = id_stage['instr']
            op, rd, rs1, rs2 = decode(instr)
            
            # Read register values with forwarding
            rs1_val = forward_val(rs1)
            rs2_val = forward_val(rs2)
            
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
        # Insert bubble (stall or jump flush)
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
        # Keep ID stage frozen (don't update)
        pass
    # else: jump_taken or branch_taken already handled above
    
    # ======== IF Stage ========
    if not halt_seen and not stall:
        if pc < len(instructions):
            pipeline['IF'] = {'instr': instructions[pc], 'pc': pc}
        else:
            pipeline['IF'] = {'instr': NOP, 'pc': pc}
    
    # Print pipeline snapshot
    print_snapshot()

# ======== Final State ========
print(f"\n=== SIMULATION COMPLETE (cycles: {cycle_count}) ===")
print_registers()