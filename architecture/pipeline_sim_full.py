program_file = "program.hex"
with open(program_file, "r") as f:
    lines = [line.strip() for line in f.readlines() if line.strip()]

instructions = [line.zfill(4) for line in lines]

reg_count = 16
mem_count =16
registers = [0]*reg_count
memory = [0]*mem_count

pipeline = {
    "IF" : None,
    "ID" : None,
    "EX" : None,
    "WB" : None
}

pc = 0
time =0
Step = 10

nop = "0000"

def decode(instr) :
    if instr in (nop, "xxxx", None) :
        return None, None, None, None
    op = int(instr[0], 16)
    rd = int(instr[1],16)
    rs1 = int(instr[2],16)
    rs2 = int(instr[3],16)
    return op, rd, rs1, rs2

def execute(op,rs1_val,rs2_val) :
    if op == 1:
        return (rs1_val+rs2_val) & 0xFFFF
    elif op == 2 :
        return (rs1_val-rs2_val) & 0xFFFF
    elif op == 3:
        return rs1_val & rs2_val
    elif op ==4 :
        return rs1_val | rs2_val
    elif op == 5:
        return memory[rs2_val %mem_count]
    elif op == 6:
        memory[rs2_val %mem_count] = rs1_val
        return None
    elif op == 7:
        return rs2_val
    else :
        return 0

def hazard_stall(id_instr, ex_instr) :
    if not id_instr or id_instr in (nop, "xxxx") :
        return False
    if not ex_instr or ex_instr in (nop, "xxxx" ) :
        return False
    _, id_rd, id_rs1, id_rs2 = decode(id_instr)
    _, ex_rd, _, _ = decode(ex_instr if isinstance(ex_instr, str) else ex_instr.get('instr', nop))
    if ex_rd in (id_rs1, id_rs2) and ex_rd !=0 :
        return True
    return False

def print_snapshot(time, pc, pipeline) :
    # EX_RD
    if pipeline['EX'] and isinstance(pipeline['EX'], dict):
        ex_rd = pipeline['EX']['rd'] if isinstance(pipeline['EX'], dict) else 0
    else:
        ex_rd = 0

    # WB_RD
    if pipeline['WB'] and isinstance(pipeline['WB'], dict):
        wb_rd = pipeline['WB']['rd'] if isinstance(pipeline['WB'], dict) else 0
    else:
        wb_rd = 0

    # WB_W
    wb_w = 1 if isinstance(pipeline['WB'], dict) else 0

    # ID_INSTR
    id_instr = pipeline['ID'] if pipeline['ID'] else "0000"
    print(f"T={time :<5} | IF_PC={pc : 04x} | ID_INSTR={id_instr} | EX_RD={ex_rd} | WB_RD={wb_rd} | WB_W={wb_w}")

def print_registers() :
    print("\n=== REGISTER FILE ===")
    for i in range(reg_count) :
        print(f"R{i} = {registers[i]:04x} ({registers[i]})")
    print("\n=== DATA MEMORY [0..7] ===")
    for i in range(8):
        print(f"mem[{i}] = {memory[i]:04x}")

sim_cycles = 100
for t in range(sim_cycles) :
    time += Step

    if pipeline['WB'] and isinstance(pipeline['WB'], dict) :
        rd = pipeline['WB']['rd']
        val = pipeline['WB']['alu_res']
        if rd is not None and rd!=0 and val is not None :
            registers[rd] = val

    if pipeline['EX']  and pipeline['EX'] not in (nop, "xxxx") :
        instr = pipeline['EX']['instr'] if isinstance(pipeline['EX'], dict) else pipeline['EX']
        op, rd, rs1, rs2 = decode (instr)
        if op is not None :
            rs1_val = registers[rs1]
            rs2_val = registers[rs2]
            alu_res = execute(op, rs1_val, rs2_val)
            pipeline['EX'] = {"rd" :rd, "alu_res": alu_res, "instr" : instr}

            if op ==7 :
                pc = alu_res
                pipeline ['IF'] = nop
                pipeline['ID'] = nop

    ex_instr_str = pipeline['EX']['instr'] if isinstance(pipeline['EX'], dict) else pipeline['EX']
    stall = hazard_stall(pipeline['ID'], ex_instr_str)
    if not stall :
        pipeline['WB'] = pipeline['EX']
        pipeline['EX'] = pipeline['ID']
        pipeline['ID'] = pipeline['IF']
        if pc < len(instructions) :
            pipeline['IF'] = instructions[pc]
        else :
            pipeline['IF'] = nop
        pc +=1
    else :
        pipeline['WB'] = pipeline['EX']
        pipeline['EX'] = {"rd" : 0, "alu_res" : 0, "instr" : nop}

    print_snapshot(time, pc, pipeline)

print_registers()