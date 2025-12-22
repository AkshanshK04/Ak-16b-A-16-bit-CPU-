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
    return val & 0xF

def to_signed(val):
    if val & 0x8000:
        return val - 0x10000
    return val

def execute(op, rs1_val, rs2_val, imm):
    if op == 0: return (rs1_val + rs2_val) & 0xFFFF
    elif op == 1: return (rs1_val - rs2_val) & 0xFFFF
    elif op == 2: return rs1_val & rs2_val
    elif op == 3: return rs1_val | rs2_val
    elif op == 4: return rs1_val ^ rs2_val
    elif op == 5: return 1 if to_signed(rs1_val) < to_signed(rs2_val) else 0
    elif op == 6: return (rs1_val + imm) & 0xFFFF
    elif op == 7: return rs1_val & (imm & 0xFFFF)
    elif op == 8: return rs1_val | (imm & 0xFFFF)
    elif op == 9: return rs1_val ^ (imm & 0xFFFF)
    elif op == 10: return (rs1_val + imm) & 0xFFFF
    elif op == 11: return (rs1_val + imm) & 0xFFFF
    elif op == 12: return (rs1_val - rs2_val) & 0xFFFF
    elif op == 13: return (rs1_val - rs2_val) & 0xFFFF
    elif op == 14: return imm & 0xFFFF
    elif op == 15: return None
    else: return 0

def hazard_stall(id_instr, ex1_stage):
    if not id_instr or id_instr == NOP:
        return False
    id_op, id_rd, id_rs1, id_rs2 = decode(id_instr)
    ex1_instr = ex1_stage.get("instr")
    if not ex1_instr or ex1_instr == NOP:
        return False
    ex1_op, ex1_rd, _, _ = decode(ex1_instr)
    if ex1_op == 10 and ex1_rd != 0:
        if ex1_rd == id_rs1 or ex1_rd == id_rs2:
            return True
    return False

def forward_val(rs, stage_name="ID"):
    if rs is None or rs == 0:
        return 0
    ex2_stage = pipeline['EX2']
    if ex2_stage.get('rd') == rs and ex2_stage.get('alu_res') is not None:
        ex2_instr = ex2_stage.get('instr', NOP)
        if ex2_instr != NOP:
            ex2_op, _, _, _ = decode(ex2_instr)
            if ex2_op not in [10,11,12,13,14,15]:
                return ex2_stage['alu_res'] & 0xFFFF
    mem_stage = pipeline['MEM']
    if mem_stage.get('rd') == rs:
        mem_instr = mem_stage.get('instr', NOP)
        if mem_instr != NOP:
            mem_op, _, _, _ = decode(mem_instr)
            if mem_op == 10:
                mem_data = mem_stage.get('mem_data')
                if mem_data is not None:
                    return mem_data & 0xFFFF
            elif mem_op not in [11,12,13,14,15]:
                alu_res = mem_stage.get('alu_res')
                if alu_res is not None:
                    return alu_res & 0xFFFF
    wb_stage = pipeline['WB']
    if wb_stage.get('rd') == rs:
        write_data = wb_stage.get('write_data')
        if write_data is not None:
            return write_data & 0xFFFF
    return registers[rs] & 0xFFFF

def print_snapshot():
    ex1_rd = pipeline['EX1'].get('rd', 0)
    ex2_rd = pipeline['EX2'].get('rd', 0)
    mem_rd = pipeline['MEM'].get('rd', 0)
    wb_rd = pipeline['WB'].get('rd', 0)
    wb_w = 1 if pipeline['WB'].get('rd',0)!=0 and pipeline['WB'].get('write_data') is not None else 0
    id_instr = pipeline['ID'].get('instr',NOP)
    if_instr = pipeline['IF'].get('instr',NOP)
    mem_instr = pipeline['MEM'].get('instr',NOP)
    wb_instr = pipeline['WB'].get('instr',NOP)
    ex2_zero = pipeline['EX2'].get('zero',0)
    print(f"T={time:<7} | IF_PC={pc:04x} | IF={if_instr} | ID={id_instr} | EX1_RD={ex1_rd:x} | EX2_RD={ex2_rd:x} EX2_Z={ex2_zero} | MEM={mem_instr} MEM_RD={mem_rd:x} | WB={wb_instr} WB_RD={wb_rd:x} WB_W={wb_w}")

def print_registers():
    print("\n=== REGISTER FILE ===")
    for i, val in enumerate(registers):
        print(f"R{i:2d} = 0x{val:04x} ({to_signed(val):6d})")
    print("\n=== DATA MEMORY [0..15] ===")
    for i in range(16):
        if i % 4 == 0: print()
        print(f"mem[{i:2d}]=0x{memory[i]:04x}  ", end="")
    print("\n")

# ===================== Simulation Loop =====================
print("=== AK-16 6-STAGE PIPELINE CPU SIMULATION START ===\n")

if len(instructions) > 0:
    pipeline['IF'] = {'instr': instructions[0], 'pc':0}

halt_seen = False

while (not halt_seen or not all(pipeline[s].get('instr')==NOP for s in ['ID','EX1','EX2','MEM','WB'])) and cycle_count<max_cycles:
    time += STEP
    cycle_count += 1

    # ===== WB =====
    wb_stage = pipeline['WB']
    if wb_stage.get('rd',0)!=0 and wb_stage.get('write_data') is not None:
        wb_instr = wb_stage.get('instr',NOP)
        if wb_instr != NOP:
            op,_,_,_ = decode(wb_instr)
            if op not in [11,12,13,14,15]:
                registers[wb_stage['rd']] = wb_stage['write_data'] & 0xFFFF

    # ===== MEM =====
    mem_stage = pipeline['MEM']
    write_data = None
    mem_data = None
    if mem_stage.get('instr') != NOP:
        op,rd,_,_ = decode(mem_stage['instr'])
        alu_res_mem = mem_stage.get('alu_res')
        if op==10 and alu_res_mem is not None:
            addr = alu_res_mem & 0xFF
            mem_data = memory[addr] & 0xFFFF
            write_data = mem_data
            pipeline['MEM']['mem_data'] = mem_data
        elif op==11 and alu_res_mem is not None:
            addr = alu_res_mem & 0xFF
            store_data = mem_stage.get('rs2_val',0) & 0xFFFF
            memory[addr] = store_data
            write_data = None
        elif op not in [12,13,14,15]:
            write_data = alu_res_mem
        else:
            write_data = None
        pipeline['MEM']['write_data'] = write_data

    # ===== MEM->WB =====
    pipeline['WB'] = {
        'instr': mem_stage.get('instr',NOP),
        'rd': mem_stage.get('rd',0),
        'write_data': write_data,
        'pc': mem_stage.get('pc',0)
    }

    # ===== EX2->MEM =====
    ex2_stage = pipeline['EX2']
    pipeline['MEM'] = {
        'instr': ex2_stage.get('instr',NOP),
        'rd': ex2_stage.get('rd',0),
        'alu_res': ex2_stage.get('alu_res'),
        'rs2_val': ex2_stage.get('rs2_val',0),
        'zero': ex2_stage.get('zero',0),
        'branch_target': ex2_stage.get('branch_target',0),
        'pc': ex2_stage.get('pc',0)
    }

    # ===== EX1 =====
    ex1_stage = pipeline['EX1']
    alu_res = None
    branch_taken = False
    jump_taken = False
    new_pc = None
    zero = 0

    if ex1_stage.get('instr') != NOP:
        instr = ex1_stage['instr']
        op,rd,rs1,rs2 = decode(instr)
        imm = sign_extend_4bit(rs2)
        rs1_val = forward_val(ex1_stage.get('rs1',rs1),"EX1")
        rs2_val = forward_val(ex1_stage.get('rs2',rs2),"EX1")
        alu_res = execute(op,rs1_val,rs2_val,imm)
        zero = 1 if (alu_res is not None and alu_res==0) else 0
        pipeline['EX1']['alu_res'] = alu_res
        pipeline['EX1']['rd'] = rd
        pipeline['EX1']['zero'] = zero
        pipeline['EX1']['rs2_val'] = rs2_val
        branch_target = ((ex1_stage.get('pc',0)+1)+sign_extend_4bit(rd)) & 0xFFFF
        pipeline['EX1']['branch_target'] = branch_target
        if op==14:  # JUMP
            new_pc = imm & 0xFFFF
            jump_taken = True
        elif op==15:
            halt_seen = True

    # ===== EX1->EX2 =====
    ex1_rs2_val = ex1_stage.get('rs2_val',0)
    if ex1_stage.get('instr') != NOP:
        op_ex1, rd_ex1, _, _ = decode(ex1_stage['instr'])
        if op_ex1 == 11:
            ex1_rs2_val = forward_val(rd_ex1,"EX1")
    pipeline['EX2'] = {
        'instr': ex1_stage.get('instr',NOP),
        'rd': ex1_stage.get('rd',0),
        'alu_res': alu_res,
        'rs2_val': ex1_rs2_val,
        'zero': zero,
        'branch_target': ex1_stage.get('branch_target',0),
        'pc': ex1_stage.get('pc',0)
    }

    # ===== Branch/Jump in EX2 =====
    ex2_instr_check = pipeline['EX2'].get('instr')
    if ex2_instr_check and ex2_instr_check != NOP:
        op2, rd2, rs1_2, rs2_2 = decode(ex2_instr_check)
        ex2_zero = pipeline['EX2'].get('zero',0)
        if op2==12 and ex2_zero==1:  # BEQ
            new_pc = pipeline['EX2']['branch_target']
            branch_taken = True
        elif op2==13 and ex2_zero==0:  # BNE
            new_pc = pipeline['EX2']['branch_target']
            branch_taken = True
        elif op2==14:  # JUMP
            new_pc = pipeline['EX2']['branch_target']
            branch_taken = True
        elif op2==15:  # HALT
            halt_seen = True
        if branch_taken and new_pc is not None:
            pipeline['IF'] = {'instr': NOP, 'pc': pc}
            pipeline['ID'] = {'instr': NOP, 'pc': pc}
            pc = new_pc

    # ===== Hazard Detection =====
    stall = hazard_stall(pipeline['ID'].get('instr'), pipeline['EX1'])

    # ===== ID->EX1 =====
    if not stall:
        id_stage = pipeline['ID']
        if id_stage.get('instr') != NOP:
            instr = id_stage['instr']
            op, rd, rs1, rs2 = decode(instr)
            rs1_val = forward_val(rs1,"ID")
            rs2_val = forward_val(rs2,"ID")
            pipeline['EX1'] = {
                'instr': instr,
                'rd': rd,
                'rs1': rs1,
                'rs2': rs2,
                'rs1_val': rs1_val,
                'rs2_val': rs2_val,
                'pc': id_stage.get('pc',0)
            }
        else:
            pipeline['EX1'] = {'instr':NOP,'pc':0}
    else:
        pipeline['EX1'] = {'instr':NOP,'pc':0}

    # ===== IF->ID =====
    if not stall and not branch_taken and not jump_taken:
        pipeline['ID'] = {'instr':pipeline['IF'].get('instr',NOP),'pc':pipeline['IF'].get('pc',0)}
        if not halt_seen:
            pc += 1

    # ===== IF Stage =====
    if not halt_seen and not stall:
        if pc < len(instructions):
            pipeline['IF'] = {'instr':instructions[pc],'pc':pc}
        else:
            pipeline['IF'] = {'instr':NOP,'pc':pc}

    # ===== Print =====
    print_snapshot()

# ===== Final =====
print(f"\n=== SIMULATION COMPLETE (cycles: {cycle_count}) ===")
print_registers()
