#include <bits/stdc++.h>
using namespace std;

vector<vector<int>> board(9, vector<int>(9));

bool isSafe(int k, int i, int j, vector<set<int>> &row, vector<set<int>> &col, vector<set<int>> &box)
{
    if (row[i].count(k) || col[j].count(k) || box[(i / 3) * 3 + j / 3].count(k))
        return false;
    return true;
}

bool solve(vector<set<int>> &r, vector<set<int>> &c, vector<set<int>> &box)
{
    for (int i = 0; i < 9; i++)
    {
        for (int j = 0; j < 9; j++)
        {
            if (board[i][j] == 0)
            {
                for (int k = 1; k <= 9; k++)
                {
                    if (isSafe(k, i, j, r, c, box))
                    {
                        board[i][j] = k;
                        r[i].insert(k);
                        c[j].insert(k);
                        box[(i / 3) * 3 + j / 3].insert(k);

                        if (solve(r, c, box))
                            return true;

                        board[i][j] = 0;
                        r[i].erase(k);
                        c[j].erase(k);
                        box[(i / 3) * 3 + j / 3].erase(k);
                    }
                }
                return false;
            }
        }
    }
    return true;
}

int main()
{
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    vector<set<int>> row(9), col(9), box(9);

    for (int i = 0; i < 9; i++)
    {
        for (int j = 0; j < 9; j++)
        {
            cin >> board[i][j];
            if (board[i][j] != 0)
            {
                row[i].insert(board[i][j]);
                col[j].insert(board[i][j]);
                box[(i / 3) * 3 + (j / 3)].insert(board[i][j]);
            }
        }
    }

    solve(row, col, box);

    cout << "\n";
    for (int i = 0; i < 9; i++)
    {
        for (int j = 0; j < 9; j++)
            cout << board[i][j] << " ";
        cout << "\n";
    }

    return 0;
}
