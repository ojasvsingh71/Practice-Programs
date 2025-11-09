# Enhanced Fully Observable Chess Agent with Castling, En-passant, and Game Status Detection
from dataclasses import dataclass
from typing import Optional, List, Tuple, Set
import copy, random
Coords = Tuple[int,int]

def in_bounds(r,c): return 0<=r<8 and 0<=c<8
def rc_to_alg(rc: Coords) -> str:
    r,c = rc; return "abcdefgh"[c] + str(8-r)
def alg_to_rc(s: str) -> Coords:
    file = "abcdefgh".index(s[0]); rank = 8-int(s[1]); return (rank,file)

@dataclass
class Piece:
    kind: str  # 'P','N','B','R','Q','K'
    color: str # 'w' or 'b'
    has_moved: bool = False
    def __repr__(self): return f"{self.color}{self.kind}"

class Board:
    def __init__(self):
        self.grid: List[List[Optional[Piece]]] = [[None]*8 for _ in range(8)]
        self.setup_starting_position()
        self.en_passant_target: Optional[Coords] = None  # square where en-passant capture is possible this turn
        self.last_move = None  # (src, dst)
    
    def setup_starting_position(self):
        for c in range(8):
            self.grid[1][c] = Piece('P','b')
            self.grid[6][c] = Piece('P','w')
        # rooks
        self.grid[0][0] = Piece('R','b'); self.grid[0][7] = Piece('R','b')
        self.grid[7][0] = Piece('R','w'); self.grid[7][7] = Piece('R','w')
        # knights
        self.grid[0][1] = Piece('N','b'); self.grid[0][6] = Piece('N','b')
        self.grid[7][1] = Piece('N','w'); self.grid[7][6] = Piece('N','w')
        # bishops
        self.grid[0][2] = Piece('B','b'); self.grid[0][5] = Piece('B','b')
        self.grid[7][2] = Piece('B','w'); self.grid[7][5] = Piece('B','w')
        # queens and kings
        self.grid[0][3] = Piece('Q','b'); self.grid[0][4] = Piece('K','b')
        self.grid[7][3] = Piece('Q','w'); self.grid[7][4] = Piece('K','w')
    
    def piece_at(self, rc: Coords) -> Optional[Piece]:
        r,c = rc; return self.grid[r][c]
    def set_piece(self, rc: Coords, p: Optional[Piece]):
        r,c = rc; self.grid[r][c] = p
    def clone(self):
        return copy.deepcopy(self)
    def pretty_print(self):
        for r in range(8):
            row = []
            for c in range(8):
                p = self.grid[r][c]; row.append(str(p) if p else '--')
            print(f"{8-r} " + " ".join(row))
        print("   a   b   c   d   e   f   g   h\n")
    # moved_piece used to be simple; now handle castling and en-passant
    def move_piece(self, src: Coords, dst: Coords):
        piece = self.piece_at(src)
        if piece is None: raise ValueError("No piece at source")
        sr,sc = src; dr,dc = dst
        # detect en-passant capture: pawn moves diagonally to en_passant_target
        if piece.kind == 'P' and self.en_passant_target and dst == self.en_passant_target and sc != dc:
            # remove the pawn that moved two squares in previous move
            # captured pawn sits behind the en_passant_target relative to moving pawn's direction
            moving_dr = -1 if piece.color=='w' else 1
            captured_pos = (dr - moving_dr, dc)
            # remove captured pawn
            self.set_piece(captured_pos, None)
        # detect castling: king moves two squares horizontally
        if piece.kind == 'K' and abs(dc - sc) == 2:
            # kingside
            if dc == 6:
                rook_src = (sr,7); rook_dst = (sr,5)
            else:  # queenside (dc==2)
                rook_src = (sr,0); rook_dst = (sr,3)
            rook = self.piece_at(rook_src)
            if rook is None or rook.kind != 'R':
                raise ValueError("Invalid castling rook")
            # move rook
            self.set_piece(rook_dst, rook)
            self.set_piece(rook_src, None)
            rook.has_moved = True
        # normal move / capture
        self.set_piece(dst, piece)
        self.set_piece(src, None)
        # pawn promotion simpl: auto-queen
        if piece.kind == 'P':
            if (piece.color=='w' and dr==0) or (piece.color=='b' and dr==7):
                piece.kind = 'Q'
        piece.has_moved = True
        # update en_passant target: only when a pawn moves two squares forward from its start rank
        self.en_passant_target = None
        if piece.kind == 'P' and abs(dr - sr) == 2:
            # square passed over
            mid_r = (sr + dr)//2
            self.en_passant_target = (mid_r, sc)
        # store last move
        self.last_move = (src, dst)

# attack map helper (used by is_in_check and for castling safety checks)
def squares_attacked_by(board: Board, color: str) -> Set[Coords]:
    attacked = set()
    for r in range(8):
        for c in range(8):
            p = board.piece_at((r,c))
            if not p or p.color != color: continue
            if p.kind == 'P':
                dr = -1 if color=='w' else 1
                for dc in (-1,1):
                    nr, nc = r+dr, c+dc
                    if in_bounds(nr,nc):
                        attacked.add((nr,nc))
            elif p.kind == 'N':
                for dr,dc in [(2,1),(2,-1),(-2,1),(-2,-1),(1,2),(1,-2),(-1,2),(-1,-2)]:
                    nr, nc = r+dr, c+dc
                    if in_bounds(nr,nc): attacked.add((nr,nc))
            elif p.kind in ('B','R','Q'):
                directions = []
                if p.kind in ('B','Q'): directions += [(-1,-1),(-1,1),(1,-1),(1,1)]
                if p.kind in ('R','Q'): directions += [(-1,0),(1,0),(0,-1),(0,1)]
                for dr,dc in directions:
                    nr, nc = r+dr, c+dc
                    while in_bounds(nr,nc):
                        attacked.add((nr,nc))
                        if board.piece_at((nr,nc)) is not None: break
                        nr += dr; nc += dc
            elif p.kind == 'K':
                for dr in (-1,0,1):
                    for dc in (-1,0,1):
                        if dr==0 and dc==0: continue
                        nr, nc = r+dr, c+dc
                        if in_bounds(nr,nc): attacked.add((nr,nc))
    return attacked

def is_in_check(board: Board, color: str) -> bool:
    # find king
    king_pos = None
    for r in range(8):
        for c in range(8):
            p = board.piece_at((r,c))
            if p and p.color==color and p.kind=='K':
                king_pos = (r,c); break
        if king_pos: break
    if not king_pos: return True
    enemy = 'b' if color=='w' else 'w'
    attacked = squares_attacked_by(board, enemy)
    return king_pos in attacked

# raw moves (without checking for leaving king in check). includes castling & en-passant possibilities.
def raw_moves_for_piece(board: Board, src: Coords) -> List[Coords]:
    piece = board.piece_at(src)
    if not piece: return []
    r,c = src; moves = []
    color = piece.color; enemy = 'b' if color=='w' else 'w'
    if piece.kind == 'P':
        dr = -1 if color=='w' else 1
        one = (r+dr, c)
        if in_bounds(*one) and board.piece_at(one) is None:
            moves.append(one)
            start_rank = 6 if color=='w' else 1
            two = (r+2*dr, c)
            if r == start_rank and board.piece_at(two) is None:
                moves.append(two)
        for dc in (-1,1):
            cap = (r+dr, c+dc)
            if in_bounds(*cap):
                tgt = board.piece_at(cap)
                if tgt and tgt.color == enemy:
                    moves.append(cap)
            # en-passant capture possibility: capturing to the en_passant_target
            if board.en_passant_target and board.en_passant_target == (r+dr, c+dc):
                moves.append((r+dr, c+dc))
    elif piece.kind == 'N':
        deltas = [(2,1),(2,-1),(-2,1),(-2,-1),(1,2),(1,-2),(-1,2),(-1,-2)]
        for dr,dc in deltas:
            nr, nc = r+dr, c+dc
            if in_bounds(nr,nc):
                tgt = board.piece_at((nr,nc))
                if tgt is None or tgt.color == enemy: moves.append((nr,nc))
    elif piece.kind in ('B','R','Q'):
        directions = []
        if piece.kind in ('B','Q'): directions += [(-1,-1),(-1,1),(1,-1),(1,1)]
        if piece.kind in ('R','Q'): directions += [(-1,0),(1,0),(0,-1),(0,1)]
        for dr,dc in directions:
            nr,nc = r+dr, c+dc
            while in_bounds(nr,nc):
                tgt = board.piece_at((nr,nc))
                if tgt is None: moves.append((nr,nc))
                else:
                    if tgt.color == enemy: moves.append((nr,nc))
                    break
                nr += dr; nc += dc
    elif piece.kind == 'K':
        for dr in (-1,0,1):
            for dc in (-1,0,1):
                if dr==0 and dc==0: continue
                nr,nc = r+dr, c+dc
                if in_bounds(nr,nc):
                    tgt = board.piece_at((nr,nc))
                    if tgt is None or tgt.color == enemy: moves.append((nr,nc))
        # Castling (only from initial king file and if king hasn't moved)
        if not piece.has_moved and c==4:
            # must not be in check currently
            if not is_in_check(board, color):
                # kingside
                rook_pos = (r,7); rook = board.piece_at(rook_pos)
                if rook and rook.kind=='R' and not rook.has_moved:
                    # squares between king and rook must be empty: cols 5 and 6
                    if board.piece_at((r,5)) is None and board.piece_at((r,6)) is None:
                        # squares king passes through (5 and 6) must not be attacked
                        attacked = squares_attacked_by(board, enemy)
                        if (r,5) not in attacked and (r,6) not in attacked:
                            moves.append((r,6))
                # queenside
                rook_pos = (r,0); rook = board.piece_at(rook_pos)
                if rook and rook.kind=='R' and not rook.has_moved:
                    # squares between king and rook must be empty: cols 1,2,3
                    if board.piece_at((r,1)) is None and board.piece_at((r,2)) is None and board.piece_at((r,3)) is None:
                        attacked = squares_attacked_by(board, enemy)
                        if (r,3) not in attacked and (r,2) not in attacked:
                            moves.append((r,2))
    return moves

def legal_moves_for_piece(board: Board, src: Coords) -> List[Coords]:
    piece = board.piece_at(src)
    if not piece: return []
    candidates = raw_moves_for_piece(board, src)
    legal = []
    for dst in candidates:
        b2 = board.clone()
        b2.move_piece(src, dst)
        if not is_in_check(b2, piece.color):
            legal.append(dst)
    return legal

def all_legal_moves(board: Board, color: str) -> List[Tuple[Coords,Coords]]:
    moves = []
    for r in range(8):
        for c in range(8):
            p = board.piece_at((r,c))
            if p and p.color==color:
                for dst in legal_moves_for_piece(board,(r,c)):
                    moves.append(((r,c),dst))
    return moves

MATERIAL = {'P':1,'N':3,'B':3,'R':5,'Q':9,'K':100}

class FullyObservableAgent:
    def __init__(self,color): self.color=color
    def perceive(self,board): return board
    def evaluate_capture(self,board,src,dst):
        tgt = board.piece_at(dst); return MATERIAL[tgt.kind] if tgt else 0
    def pick_move(self, board: Board):
        legal = all_legal_moves(board, self.color)
        if not legal: return None
        captures = [(s,d,self.evaluate_capture(board,s,d)) for (s,d) in legal if board.piece_at(d) is not None]
        if captures:
            captures.sort(key=lambda x:x[2], reverse=True)
            return (captures[0][0], captures[0][1])
        safe_moves = []
        enemy = 'b' if self.color=='w' else 'w'
        for s,d in legal:
            b2 = board.clone(); b2.move_piece(s,d)
            attacked = False
            for (es,ed) in all_legal_moves(b2, enemy):
                if ed == d: attacked = True; break
            if not attacked: safe_moves.append((s,d))
        if safe_moves: return random.choice(safe_moves)
        return random.choice(legal)

# game status helper
def game_status(board: Board, color: str) -> str:
    moves = all_legal_moves(board, color)
    if moves: return "ongoing"
    if is_in_check(board, color): return "checkmate"
    return "stalemate"

# --- Demos ---
print("Starting position:")
b = Board(); b.pretty_print()

# Demo: enable white castling by clearing between pieces and ensuring hasn't moved
# We'll prepare a simple position: white king & rooks unmoved at e1, a1, h1, clear between
demo = Board()
# clear knights and bishops between king and rooks
for pos_alg in ['b1','c1','f1','g1']:
    demo.set_piece(alg_to_rc(pos_alg), None)
print("Demo board for castling (white):")
demo.pretty_print()
# show legal moves for white king at e1 (should include c1 and g1 castling destinations as 'c1' and 'g1' algebraic)
king_src = alg_to_rc('e1')
king_moves = legal_moves_for_piece(demo, king_src)
print("Legal king moves from e1:", [rc_to_alg(m) for m in king_moves])

# perform kingside castle move (e1->g1) if legal
if alg_to_rc('g1') in king_moves:
    demo.move_piece(king_src, alg_to_rc('g1'))
    print("After white kingside castling (e1->g1):")
    demo.pretty_print()

# Demo: en-passant
ep = Board()
# clear pieces and set up pawns for en-passant: white pawn on e5, black pawn moves d7->d5
# place white pawn at e5 (which is alg e5 -> rc)
ep = Board()
# clear to empty
ep.grid = [[None]*8 for _ in range(8)]
# place white pawn at e5 and black pawn at d7
ep.set_piece(alg_to_rc('e5'), Piece('P','w'))
ep.set_piece(alg_to_rc('d7'), Piece('P','b'))
print("Before black double-step (for en-passant):")
ep.pretty_print()
# black pawn double-step d7->d5
ep.move_piece(alg_to_rc('d7'), alg_to_rc('d5'))
print("After black double-step d7->d5, en_passant_target:", rc_to_alg(ep.en_passant_target) if ep.en_passant_target else None)
ep.pretty_print()
# Now legal moves for white pawn at e5 should include d6 (en-passant capture square)
wp_src = alg_to_rc('e5')
legal_wp = legal_moves_for_piece(ep, wp_src)
print("Legal moves for white pawn at e5 (should include d6):", [rc_to_alg(m) for m in legal_wp])
# perform en-passant if available
if alg_to_rc('d6') in legal_wp:
    ep.move_piece(wp_src, alg_to_rc('d6'))
    print("After en-passant capture e5xd6 (capturing pawn that was on d5):")
    ep.pretty_print()

# Demo: simple checkmate detection (Fool's mate setup)
fm = Board()
# clear and setup quick mate: white f2 pawn, g2 pawn to allow black's Q to mate
fm.grid = [[None]*8 for _ in range(8)]
# place kings
fm.set_piece(alg_to_rc('e1'), Piece('K','w'))
fm.set_piece(alg_to_rc('e8'), Piece('K','b'))
# white pawns and pieces in a vuln position
fm.set_piece(alg_to_rc('f2'), Piece('P','w'))
fm.set_piece(alg_to_rc('g2'), Piece('P','w'))
# black queen and pawn moves to deliver mate: put black queen on d4 delivering mate after sequence (setup final position)
fm.set_piece(alg_to_rc('d4'), Piece('Q','b'))
fm.set_piece(alg_to_rc('f7'), Piece('P','b'))  # irrelevant
print("Fool's-mate-like demo position:")
fm.pretty_print()
print("White status:", game_status(fm, 'w'))
print("Black status:", game_status(fm, 'b'))

# Example: let agent play a few moves with enhanced rules
play_board = Board()
agent_w = FullyObservableAgent('w'); agent_b = FullyObservableAgent('b')
print("Agents play 4 ply with enhanced rules:")
for ply in range(4):
    for agent in (agent_w, agent_b):
        mv = agent.pick_move(play_board)
        if not mv:
            print(agent.color, "has no move:", game_status(play_board, agent.color))
            break
        s,d = mv; print(f"{agent.color}: {rc_to_alg(s)} -> {rc_to_alg(d)}")
        play_board.move_piece(s,d)
print("Final board after moves:")
play_board.pretty_print()
