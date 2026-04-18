import * as vscode from 'vscode';

let outputChannel: vscode.OutputChannel;

export function activate(context: vscode.ExtensionContext) {
    vscode.window.showInformationMessage('C++ Boilerplate AUTO is STARTING!');
    outputChannel = vscode.window.createOutputChannel('C++ Boilerplate Auto');
    outputChannel.appendLine('C++ Boilerplate Auto: Global Activation Successful!');
    outputChannel.show(true);

    const getTemplate = () => {
        const template = vscode.workspace.getConfiguration('cpp-boilerplate-auto').get<string>('template') || '';
        outputChannel.appendLine(`Fetched Template: ${template.substring(0, 20)}...`);
        return template;
    };

    const isAutoInsertEnabled = () => {
        const enabled = vscode.workspace.getConfiguration('cpp-boilerplate-auto').get<boolean>('autoInsert') !== false;
        outputChannel.appendLine(`Is Auto-Insert Enabled? ${enabled}`);
        return enabled;
    };

    const insertBoilerplate = async (editor: vscode.TextEditor | undefined, triggerSource: string) => {
        if (!editor) {
            outputChannel.appendLine(`[${triggerSource}] No active editor found.`);
            return;
        }
        
        const document = editor.document;
        outputChannel.appendLine(`[${triggerSource}] Checking document: ${document.fileName} (Language: ${document.languageId})`);

        if (document.languageId === 'cpp') {
            const currentText = document.getText().trim();
            outputChannel.appendLine(`[${triggerSource}] Document text length: ${currentText.length}`);
            
            if (currentText.length === 0) {
                const template = getTemplate();
                if (template) {
                    outputChannel.appendLine(`[${triggerSource}] Inserting boilerplate...`);
                    const success = await editor.insertSnippet(new vscode.SnippetString(template));
                    if (success) {
                        outputChannel.appendLine(`[${triggerSource}] Success!`);
                        vscode.window.setStatusBarMessage('C++ Boilerplate inserted!', 3000);
                    } else {
                        outputChannel.appendLine(`[${triggerSource}] Failed to insert snippet.`);
                    }
                }
            } else {
                outputChannel.appendLine(`[${triggerSource}] File is not empty, skipping.`);
            }
        } else {
            outputChannel.appendLine(`[${triggerSource}] Language is not CPP, skipping.`);
        }
    };

    // Trigger 1: Change in active editor
    let activeEditorSubscription = vscode.window.onDidChangeActiveTextEditor(editor => {
        if (isAutoInsertEnabled()) {
            insertBoilerplate(editor, 'EditorChange');
        }
    });

    // Trigger 2: Manual command
    let commandDisposable = vscode.commands.registerCommand('cpp-boilerplate-auto.insertBoilerplate', () => {
        insertBoilerplate(vscode.window.activeTextEditor, 'ManualCommand');
    });

    // Check immediately on activation
    if (vscode.window.activeTextEditor && isAutoInsertEnabled()) {
        outputChannel.appendLine('Immediate check on activation...');
        insertBoilerplate(vscode.window.activeTextEditor, 'Startup');
    }

    context.subscriptions.push(activeEditorSubscription, commandDisposable);
}

export function deactivate() {
    if (outputChannel) {
        outputChannel.dispose();
    }
}