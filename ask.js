const readline = require('readline');

const AskQuestion = (rl, question) => {
    return new Promise(resolve => {
        rl.question(question, (answer) => {
            resolve(answer);
        });
    });
}

const Ask = function(rl, questions) {
    return new Promise(async resolve => {
        let results = [];
        for(let i=0;i < questions.length;i++) {
            const result = await AskQuestion(rl, questions[i]);
            results.push(result);
        }
        resolve(results);
    })
}

module.exports = {
    askQuestions: Ask
}