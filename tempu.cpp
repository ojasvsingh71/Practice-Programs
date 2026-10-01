#include <bits/stdc++.h>
using namespace std;

struct Vec {
    int x, y, z;
};

Vec operator+(Vec a, Vec b) {
    return {a.x + b.x, a.y + b.y, a.z + b.z};
}

Vec operator*(Vec a, int k) {
    return {a.x * k, a.y * k, a.z * k};
}

int dot(Vec a, Vec b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

Vec cross(Vec a, Vec b) {
    return {
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    };
}

bool same(Vec a, Vec b) {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

Vec rotate90(Vec v, Vec axis, int dir) {
    Vec c = cross(axis, v);

    if (dir == -1)
        c = c * -1;

    return c + axis * dot(axis, v);
}

string normalize(const string& s) {
    int id[256];
    fill(begin(id), end(id), -1);

    int nxt = 0;
    string res;
    res.reserve(24);

    for (unsigned char c : s) {
        if (id[c] == -1)
            id[c] = nxt++;

        res.push_back(char('0' + id[c]));
    }

    return res;
}
string applyMove(const string& s, const array<int, 24>& p) {
    string t(24, ' ');

    for (int i = 0; i < 24; ++i)
        t[i] = s[p[i]];

    return t;
}

vector<array<int, 24>> buildMoves() {



    Vec N[6] = {
        {0, 1, 0},    // Top
        {0, 0, 1},    // Front
        {0,-1, 0},    // Down
        {0, 0,-1},    // Back
        {-1,0, 0},    // Left
        {1, 0, 0}     // Right
    };

    Vec R[6] = {
        {1, 0, 0},    // Top
        {1, 0, 0},    // Front
        {1, 0, 0},    // Down
        {1, 0, 0},    // Back
        {0, 0, 1},    // Left
        {0, 0,-1}     // Right
    };

    Vec D[6] = {
        {0, 0, 1},    // Top
        {0,-1, 0},    // Front
        {0, 0,-1},    // Down
        {0, 1, 0},    // Back
        {0,-1, 0},    // Left
        {0,-1, 0}     // Right
    };

    Vec pos[24], normal[24];

    for (int f = 0; f < 6; ++f) {
        for (int row = 0; row < 2; ++row) {
            for (int col = 0; col < 2; ++col) {

                int i = 4 * f + 2 * row + col;

                int cs = (col == 0 ? -1 : 1);
                int rs = (row == 0 ? -1 : 1);

                pos[i] = N[f] + R[f] * cs + D[f] * rs;
                normal[i] = N[f];
            }
        }
    }

    auto findSticker = [&](Vec p, Vec n) {

        for (int i = 0; i < 24; ++i) {
            if (same(pos[i], p) && same(normal[i], n))
                return i;
        }

        return -1;
    };

    vector<array<int,24>> moves;

    for (int f = 0; f < 6; ++f) {

        for (int dir : {+1, -1}) {

            array<int,24> perm{};

            for (int i = 0; i < 24; ++i) {

                if (dot(pos[i], N[f]) == 1) {

                    Vec newPos =
                        rotate90(pos[i], N[f], dir);

                    Vec newNormal =
                        rotate90(normal[i], N[f], dir);

                    int j = findSticker(newPos, newNormal);

                    perm[j] = i;
                }
                else {
                    perm[i] = i;
                }
            }

            moves.push_back(perm);
        }
    }

    return moves;
}

int main() {

    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    string cube(24, ' ');

    for (char& c : cube)
        cin >> c;

    auto moves = buildMoves();


    const string solved =
        "UUUUEEEEDDDDBBBBLLLLRRRR";

    const string goal = normalize(solved);


    unordered_set<string> reachable;
    reachable.reserve(5000);

    queue<pair<string,int>> q;

    reachable.insert(goal);
    q.push({goal, 0});

    while (!q.empty()) {

        auto [cur, depth] = q.front();
        q.pop();

        if (depth == 4)
            continue;

        for (const auto& move : moves) {

            string next =
                normalize(applyMove(cur, move));

            if (reachable.insert(next).second) {
                q.push({next, depth + 1});
            }
        }
    }

    vector<array<int,3>> corners = {

        {2,  4, 17},   // UFL
        {3,  5, 20},   // UFR
        {0, 14, 16},   // UBL
        {1, 15, 21},   // UBR

        {8,  6, 19},   // DFL
        {9,  7, 22},   // DFR
        {10, 12, 18},  // DBL
        {11, 13, 23}   // DBR
    };


    for (auto c : corners) {

        int a = c[0];
        int b = c[1];
        int d = c[2];

        for (int dir = 0; dir < 2; ++dir) {

            string fixed = cube;

            if (dir == 0) {

                fixed[a] = cube[b];
                fixed[b] = cube[d];
                fixed[d] = cube[a];

            } else {

                fixed[a] = cube[d];
                fixed[b] = cube[a];
                fixed[d] = cube[b];
            }

            if (reachable.count(normalize(fixed))) {

                string answer = {
                    cube[a],
                    cube[b],
                    cube[d]
                };

                sort(answer.begin(), answer.end());

                cout << answer << '\n';
                return 0;
            }
        }
    }

    return 0;
}