function modifier(score) {
    return Math.floor((score-10) / 2);
}

function alertStat(elem) {
    console.log(elem);
    var str = elem.id + " " + elem.value + " (" + modifier(elem.value) + ")";
    alert(str);
}

function prof(lvl) {
    return 1 + Math.ceil(lvl / 4);
}

function setProficiency(lvl) {
    document.getElementById("proficiency").value = prof(lvl);
}

function addSkill(skill) {
    document.getElementById(skill).checked = true;
}

function updateSkill(skill_pool) {
    return function(elem) {
        console.log(elem);
        elem.checked = skill_pool.includes(elem.id);
    };
}

function updateSkills(skill_pool) {
    document.getElementsByName("skill").forEach(function(elem) {
        if (skill_pool.includes(elem.id.slice(6))) {
            elem.removeAttribute("disabled");
        } else {
            elem.setAttribute("disabled", true);
        }
    });
}

function update() {
//    document.getElementsByName("skill").forEach(function(x) {if (x.checked) {alert(x.value);}});
//    document.getElementsByName("name")[0].value = "A nice name";
//    document.getElementsByName("ability").forEach(alertStat);
    setProficiency(document.getElementById("level").value);
    var pkmn = classes[document.getElementById("pokemon").value];
//    document.getElementsByName("skill").forEach(updateSkill(classes[pkmn].skill_pool));
    updateSkills(pkmn.skill_pool);
}