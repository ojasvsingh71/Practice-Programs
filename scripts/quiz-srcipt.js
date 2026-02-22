// STRICTLY FOR EDUCATION & PRACTICE PURPOSE //


(async function(){
  'use strict';
  const LOG = (...a) => console.log('🤖 [Quiz-Hacker]', ...a);
  const sleep = ms => new Promise(r => setTimeout(r, ms));

  const doc = document;
  const win = window;
  
  const urlParams = new URLSearchParams(win.location.search);
  const quizId = urlParams.get('id') || urlParams.get('content_id') || 'current_quiz';
  const storageKey = `quiz_answers_${quizId}`;

  function getVisibleInputs() {
      return Array.from(doc.querySelectorAll('input[type="radio"], input[type="checkbox"]'))
                  .filter(el => el.offsetParent !== null || (el.parentElement && el.parentElement.offsetParent !== null));
  }

  function findAndClickButton(includeWords, excludeWords) {
      const els = Array.from(doc.querySelectorAll('button, a, input[type="button"], input[type="submit"], .btn, .button'));
      for (const el of els) {
          if (el.offsetParent === null) continue; 
          const txt = (el.innerText || el.value || el.title || el.className || el.id || '').toLowerCase().trim();
          if (includeWords.some(w => txt.includes(w)) && !excludeWords.some(w => txt.includes(w))) {
              el.disabled = false; 
              el.click();
              return true;
          }
      }
      return false;
  }

  // --- AUTO-FILL MODE (Run #2) ---
  const savedAnswers = localStorage.getItem(storageKey);
  if (savedAnswers) {
      const mapping = JSON.parse(savedAnswers);
      const doFill = confirm(`✅ Found ${mapping.length} saved answers!\n\nDo you want to AUTO-FILL the quiz with 100% correct answers now?\n\n👉 CLICK 'CANCEL' TO DELETE BAD ANSWERS AND RE-PROBE 👈`);
      
      if (doFill) {
          LOG("Starting Auto-Fill pass...");
          let currentQ = 0;

          while(true) {
              let inputs = getVisibleInputs();
              if (!inputs.length) break;
              if (currentQ >= mapping.length) break;

              const m = mapping[currentQ];
              LOG(`Filling Q${currentQ + 1}...`);
              
              let targetVals = m.corrects || [];
              let targetIdxs = m.indices || [];
              let chosenInputs = [];

              for (let j = 0; j < targetIdxs.length; j++) {
                  let val = targetVals[j] ? targetVals[j].toString() : null;
                  let idx = targetIdxs[j];
                  
                  let chosen = null;
                  if (val) chosen = inputs.find(inp => (inp.value && inp.value.toString() === val) || (inp.id && inp.id.toString() === val));
                  if (!chosen && inputs[idx]) chosen = inputs[idx];
                  if (chosen) chosenInputs.push(chosen);
              }

              if (chosenInputs.length === 0 && inputs.length > 0) chosenInputs.push(inputs[0]);

              for(let resetInp of inputs) {
                  if (resetInp.checked && !chosenInputs.includes(resetInp)) {
                      try{ resetInp.click(); } catch(e){ resetInp.checked = false; resetInp.dispatchEvent(new Event('change',{bubbles:true})); }
                      await sleep(50);
                  }
              }

              for (let chosen of chosenInputs) {
                  if (!chosen.checked) {
                      try{ chosen.click(); } catch(e){ chosen.checked = true; chosen.dispatchEvent(new Event('change',{bubbles:true})); }
                      await sleep(200); 
                  }
              }
              
              LOG("  Clicking Submit...");
              findAndClickButton(['submit', 'check'], ['quiz', 'next', 'finish', 'previous']);
              await sleep(1500); 
              
              if (currentQ < mapping.length - 1) {
                  LOG("  Clicking Next...");
                  findAndClickButton(['next'], ['submit', 'finish', 'quiz', 'previous']);
                  
                  let attempts = 0;
                  while(attempts < 10) {
                      await sleep(500);
                      let newInputs = getVisibleInputs();
                      if (newInputs.length > 0 && newInputs[0] !== inputs[0]) break; 
                      attempts++;
                  }
              } else {
                  break;
              }
              currentQ++;
          }
          LOG("🎉 Auto-Fill Complete! Submit the final quiz.");
          return;
      } else {
          localStorage.removeItem(storageKey);
          LOG("Deleted saved answers. Starting fresh probe...");
      }
  }

  // --- PROBE MODE (Run #1) ---
  LOG(`Starting new probe to discover answers for Quiz ID: ${quizId}...`);
  
  const origLog = win.console.log;
  win.__quizLogs = [];
  win.console.log = function(...args) {
      win.__quizLogs.push(args.map(String).join(' '));
      origLog.apply(this, args);
  };

  const mapping = [];
  let qNum = 1;

  while(true) {
      await sleep(1000);
      let inputs = getVisibleInputs();
      
      if (!inputs.length) {
          LOG("Waiting for inputs to appear...");
          await sleep(2000);
          inputs = getVisibleInputs();
      }
      
      if (!inputs.length) {
          LOG("No more questions found. Probe ending.");
          break;
      }

      LOG(`Probing Question ${qNum}...`);
      let isMultipleChoice = inputs.length > 0 && inputs[0].type === 'checkbox';
      let correctIndices = [];
      let correctVals = [];

      if (!isMultipleChoice) {
          // --- SINGLE CHOICE (Log Hijack) ---
          win.__quizLogs = []; 
          try{ inputs[0].click(); } catch(e){ inputs[0].checked = true; inputs[0].dispatchEvent(new Event('change',{bubbles:true})); }
          await sleep(500);
          
          LOG("  Clicking Submit to trigger log leak...");
          findAndClickButton(['submit', 'check'], ['quiz', 'next', 'finish', 'previous']);
          await sleep(2000); 
          
          let ansArray = [];
          for (let msg of win.__quizLogs) {
              let m = msg.match(/answer_array\s*:\s*([a-z0-9]+)/i);
              if (m) {
                  let val = m[1].toLowerCase();
                  ansArray.push((val === '1' || val === 'true') ? 1 : 0);
              }
          }
          
          if (ansArray.length > 0) {
              LOG("  Extracted answers from Console Logs.");
              for (let i = 0; i < ansArray.length; i++) {
                  if (ansArray[i] === 1) {
                      correctIndices.push(i);
                      if (inputs[i]) correctVals.push(inputs[i].value || inputs[i].id);
                  }
              }
          }

      } else {
          // --- MULTIPLE CHOICE (Combination Lock Cracker) ---
          LOG("  Multiple Choice detected. Initiating Combination Cracker...");
          
          // Generate all possible combinations (from 1 to 2^n - 1)
          let totalCombos = Math.pow(2, inputs.length) - 1;
          LOG(`  Testing ${totalCombos} possible combinations...`);

          let comboCracked = false;

          for (let i = 1; i <= totalCombos; i++) {
              win.__quizLogs = []; 
              
              // Uncheck all
              for(let resetInp of inputs) {
                  if (resetInp.checked) {
                      try{ resetInp.click(); } catch(e){ resetInp.checked = false; resetInp.dispatchEvent(new Event('change',{bubbles:true})); }
                      await sleep(50);
                  }
              }

              // Check specific combination using binary masking
              let currentComboIndices = [];
              for (let j = 0; j < inputs.length; j++) {
                  if ((i & (1 << j)) !== 0) {
                      currentComboIndices.push(j);
                      try{ inputs[j].click(); } catch(e){ inputs[j].checked = true; inputs[j].dispatchEvent(new Event('change',{bubbles:true})); }
                  }
              }
              
              await sleep(300);
              let clicked = findAndClickButton(['submit', 'check'], ['quiz', 'next', 'finish', 'previous']);
              if (!clicked) {
                  LOG("  ⚠️ Submit button disappeared. Quiz locked.");
                  break;
              }
              
              await sleep(1000); // Wait for server validation
              
              // Read the screen to see if the combination was accepted
              // Look for the global success message for the question
              let hasGlobalSuccess = doc.querySelector('.quiz_feedback.correct_ans, .correct-answer-global, .text-success:not(.hidden)') !== null;
              
              // Also check logs just in case they print "correct answer :true"
              let logsSayTrue = win.__quizLogs.some(msg => msg.toLowerCase().includes('correct answer :true') || msg.toLowerCase().includes('correct answer: true'));

              if (hasGlobalSuccess || logsSayTrue) {
                  LOG(`  🔓 Lock Cracked! Correct Combo: Options ${currentComboIndices.map(x=>x+1).join(', ')}`);
                  correctIndices = currentComboIndices;
                  correctVals = currentComboIndices.map(idx => inputs[idx].value || inputs[idx].id);
                  comboCracked = true;
                  break; 
              }
          }
          
          if (!comboCracked) {
             LOG("  ❌ Failed to crack combination.");
          }
      }

      // Save Results
      if (correctIndices.length > 0) {
          LOG(`  ✅ Stolen Answer(s): Options ${correctIndices.map(i=>i+1).join(', ')}`);
          mapping.push({ question: qNum, corrects: correctVals, indices: correctIndices });
      } else {
          LOG(`  ⚠️ Saving Option 1 as fallback.`);
          mapping.push({ question: qNum, corrects: [inputs[0].value || inputs[0].id || "0"], indices: [0] });
      }

      LOG("  Clicking Next...");
      let nextClicked = findAndClickButton(['next'], ['submit', 'finish', 'quiz', 'previous']);
      
      if (!nextClicked) {
          LOG("  No Next button found. End of quiz?");
          break; 
      }
      
      let attempts = 0;
      while(attempts < 10) {
          await sleep(500);
          let newInputs = getVisibleInputs();
          if (newInputs.length > 0 && newInputs[0] !== inputs[0]) break; 
          attempts++;
      }
      qNum++;
  }

  if (mapping.length > 0) {
      LOG(`Probe complete! Saved ${mapping.length} answers to memory.`);
      localStorage.setItem(storageKey, JSON.stringify(mapping));
      alert(`🤖 Probe Complete!\n\nI successfully mapped ${mapping.length} questions for this specific quiz.\n\nPlease hit 'RETAKE QUIZ' (or refresh the page to restart), and then RUN THIS SCRIPT ONE MORE TIME to Auto-Fill!`);
  } else {
      LOG("Probe failed to find any questions.");
  }
  
})();