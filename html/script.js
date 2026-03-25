// Job & Gang Creator NUI logic
// Recreated script: handles tabs, list, editor, locations, and NUI bridge.

(function () {
    const resourceName = GetParentResourceName ? GetParentResourceName() : 'job-creator';

    let currentTab = 'jobs';
    let data = {
        jobs: {},
        gangs: {},
        customJobNames: {},
        customGangNames: {},
        bossLocations: [],
        gangLocations: [],
    };
    let selectedId = null;
    let isNew = false;

    const app = document.getElementById('app');
    const listTitle = document.getElementById('listTitle');
    const itemList = document.getElementById('itemList');
    const editorPlaceholder = document.getElementById('editorPlaceholder');
    const editorForm = document.getElementById('editorForm');
    const editId = document.getElementById('editId');
    const editName = document.getElementById('editName');
    const editLabel = document.getElementById('editLabel');
    const editDefaultDuty = document.getElementById('editDefaultDuty');
    const editOffDutyPay = document.getElementById('editOffDutyPay');
    const editType = document.getElementById('editType');
    const jobOnlyFields = document.getElementById('jobOnlyFields');
    const gradesBody = document.getElementById('gradesBody');
    const btnClose = document.getElementById('btnClose');
    const btnBossMenu = document.getElementById('btnBossMenu');
    const btnGangMenu = document.getElementById('btnGangMenu');
    const btnNew = document.getElementById('btnNew');
    const btnAddGrade = document.getElementById('btnAddGrade');
    const btnDelete = document.getElementById('btnDelete');
    const btnAddBossLocation = document.getElementById('btnAddBossLocation');
    const btnAddGangLocation = document.getElementById('btnAddGangLocation');
    const bossLocationsList = document.getElementById('bossLocationsList');
    const gangLocationsList = document.getElementById('gangLocationsList');
    const locationsPanel = document.getElementById('locationsPanel');
    const selectBossJob = document.getElementById('selectBossJob');
    const selectGangGang = document.getElementById('selectGangGang');
    const toastEl = document.getElementById('toast');

    function showToast(message, type) {
        if (!toastEl) return;
        toastEl.textContent = message;
        toastEl.className = 'toast ' + (type || 'success');
        toastEl.classList.remove('hidden');
        clearTimeout(toastEl._tid);
        toastEl._tid = setTimeout(function () {
            toastEl.classList.add('hidden');
        }, 3500);
    }

    function nuiFetch(name, body) {
        return fetch('https://' + resourceName + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body || {}),
        }).then(function (r) {
            try {
                return r.json();
            } catch (e) {
                return {};
            }
        });
    }

    function getCurrentItems() {
        return currentTab === 'jobs' ? (data.jobs || {}) : (data.gangs || {});
    }

    function getItemId(item) {
        return item && item.name ? item.name : null;
    }

    function normalizeId(str) {
        if (!str) return '';
        return String(str).toLowerCase().replace(/\s+/g, '');
    }

    function jobLabel(jobId) {
        if (!jobId) return '—';
        const j = data.jobs && data.jobs[jobId];
        return (j && (j.label || j.name)) || jobId;
    }

    function gangLabel(gangId) {
        if (!gangId) return '—';
        const g = data.gangs && data.gangs[gangId];
        return (g && (g.label || g.name)) || gangId;
    }

    function formatCoords(coords) {
        if (!coords || typeof coords !== 'object') return '—';
        const x = Math.floor(Number(coords.x) || 0);
        const y = Math.floor(Number(coords.y) || 0);
        const z = Math.floor(Number(coords.z) || 0);
        return x + ', ' + y + ', ' + z;
    }

    function renderList() {
        if (!itemList) return;
        itemList.innerHTML = '';
        const items = getCurrentItems();
        const entries = Object.values(items || {}).sort(function (a, b) {
            const la = (a.label || a.name || '').toLowerCase();
            const lb = (b.label || b.name || '').toLowerCase();
            if (la < lb) return -1;
            if (la > lb) return 1;
            return 0;
        });

        entries.forEach(function (item) {
            const id = getItemId(item);
            const li = document.createElement('li');
            li.className = 'list-item' + (id === selectedId ? ' active' : '');
            li.dataset.id = id;
            li.textContent = item.label || item.name || id;
            li.addEventListener('click', function () {
                selectItem(id, false);
            });
            itemList.appendChild(li);
        });

        if (currentTab === 'locations') {
            listTitle.textContent = 'Locations';
        } else if (currentTab === 'jobs') {
            listTitle.textContent = 'Jobs';
        } else {
            listTitle.textContent = 'Gangs';
        }
    }

    function clearGrades() {
        while (gradesBody.firstChild) {
            gradesBody.removeChild(gradesBody.firstChild);
        }
    }

    function addGradeRow(grade) {
        const tr = document.createElement('tr');

        const levelTd = document.createElement('td');
        const levelInput = document.createElement('input');
        levelInput.type = 'number';
        levelInput.value = (grade && (grade.level != null ? grade.level : grade.grade)) || 0;
        levelInput.className = 'input-small';
        levelTd.appendChild(levelInput);

        const nameTd = document.createElement('td');
        const nameInput = document.createElement('input');
        nameInput.type = 'text';
        nameInput.value = grade && grade.name || '';
        nameTd.appendChild(nameInput);

        const paymentTd = document.createElement('td');
        const paymentInput = document.createElement('input');
        paymentInput.type = 'number';
        paymentInput.value = grade && grade.payment || 0;
        paymentTd.appendChild(paymentInput);

        const bossTd = document.createElement('td');
        const bossInput = document.createElement('input');
        bossInput.type = 'checkbox';
        bossInput.checked = !!(grade && (grade.isboss || grade.boss));
        bossTd.appendChild(bossInput);

        const removeTd = document.createElement('td');
        const removeBtn = document.createElement('button');
        removeBtn.type = 'button';
        removeBtn.className = 'btn-small btn-danger';
        removeBtn.textContent = '×';
        removeBtn.addEventListener('click', function () {
            tr.remove();
        });
        removeTd.appendChild(removeBtn);

        tr.appendChild(levelTd);
        tr.appendChild(nameTd);
        tr.appendChild(paymentTd);
        tr.appendChild(bossTd);
        tr.appendChild(removeTd);

        gradesBody.appendChild(tr);
    }

    function collectGrades() {
        const grades = [];
        gradesBody.querySelectorAll('tr').forEach(function (tr, idx) {
            const inputs = tr.querySelectorAll('input');
            if (inputs.length < 4) return;
            const level = parseInt(inputs[0].value, 10) || idx;
            const name = (inputs[1].value || '').trim();
            const payment = parseInt(inputs[2].value, 10) || 0;
            const boss = !!inputs[3].checked;
            if (!name) return;
            grades.push({
                level: level,
                name: name,
                payment: payment,
                isboss: boss,
            });
        });
        return grades;
    }

    function selectItem(id, createNew) {
        selectedId = id || null;
        isNew = !!createNew;

        document.querySelectorAll('.list-item').forEach(function (li) {
            li.classList.toggle('active', li.dataset.id === selectedId);
        });

        if (currentTab === 'locations') {
            editorForm.classList.add('hidden');
            editorPlaceholder.classList.add('hidden');
            locationsPanel.classList.remove('hidden');
            return;
        }

        locationsPanel.classList.add('hidden');

        if (!selectedId && !isNew) {
            editorForm.classList.add('hidden');
            editorPlaceholder.classList.remove('hidden');
            return;
        }

        editorPlaceholder.classList.add('hidden');
        editorForm.classList.remove('hidden');

        const items = getCurrentItems();
        const item = isNew ? null : items[selectedId];

        const idValue = item && item.name ? item.name : '';
        editId.value = idValue || '';
        editName.value = idValue || '';
        editLabel.value = (item && item.label) || '';

        if (currentTab === 'jobs') {
            jobOnlyFields.classList.remove('hidden');
            editDefaultDuty.checked = !!(item && item.defaultDuty);
            editOffDutyPay.checked = !!(item && item.offDutyPay);
            editType.value = (item && item.type) || '';
        } else {
            jobOnlyFields.classList.add('hidden');
            editDefaultDuty.checked = true;
            editOffDutyPay.checked = false;
            editType.value = '';
        }

        clearGrades();
        const grades = item && (item.grades || item.Grades) || [];
        if (grades.length) {
            grades.forEach(function (g) {
                addGradeRow(g);
            });
        } else if (currentTab === 'gangs') {
            addGradeRow({ level: 0, name: 'Recruit', payment: 0, isboss: true });
        } else {
            addGradeRow({ level: 0, name: 'Freelancer', payment: 0, isboss: false });
        }
    }

    function renderLocationsLists() {
        bossLocationsList.innerHTML = '';
        gangLocationsList.innerHTML = '';

        (data.bossLocations || []).forEach(function (loc) {
            const li = document.createElement('li');
            li.className = 'location-item';
            const title = document.createElement('div');
            title.className = 'location-title';
            title.textContent = (loc.name || 'Boss Menu') + ' (' + jobLabel(loc.job) + ')';
            const coords = document.createElement('div');
            coords.className = 'location-coords';
            coords.textContent = formatCoords(loc.coords);
            const remove = document.createElement('button');
            remove.type = 'button';
            remove.className = 'btn-small btn-danger';
            remove.textContent = 'Remove';
            remove.addEventListener('click', function () {
                nuiFetch('removeBossLocation', { id: loc.id || loc.name }).then(function () {
                    showToast('Location removed');
                });
            });
            li.appendChild(title);
            li.appendChild(coords);
            li.appendChild(remove);
            bossLocationsList.appendChild(li);
        });

        (data.gangLocations || []).forEach(function (loc) {
            const li = document.createElement('li');
            li.className = 'location-item';
            const title = document.createElement('div');
            title.className = 'location-title';
            title.textContent = (loc.name || 'Gang Menu') + ' (' + gangLabel(loc.gang) + ')';
            const coords = document.createElement('div');
            coords.className = 'location-coords';
            coords.textContent = formatCoords(loc.coords);
            const remove = document.createElement('button');
            remove.type = 'button';
            remove.className = 'btn-small btn-danger';
            remove.textContent = 'Remove';
            remove.addEventListener('click', function () {
                if (!loc.id) {
                    showToast('This location has no id; please recreate it.', 'error');
                    return;
                }
                nuiFetch('removeGangLocation', { id: loc.id }).then(function () {
                    showToast('Location removed');
                });
            });
            li.appendChild(title);
            li.appendChild(coords);
            li.appendChild(remove);
            gangLocationsList.appendChild(li);
        });

        // Rebuild selects
        const bossSel = selectBossJob;
        const gangSel = selectGangGang;
        const bossVal = bossSel.value;
        const gangVal = gangSel.value;
        bossSel.innerHTML = '<option value=\"\">-- Select job --</option>';
        gangSel.innerHTML = '<option value=\"\">-- Select gang --</option>';

        Object.keys(data.jobs || {}).forEach(function (id) {
            const opt = document.createElement('option');
            opt.value = id;
            opt.textContent = jobLabel(id);
            bossSel.appendChild(opt);
        });
        Object.keys(data.gangs || {}).forEach(function (id) {
            const opt = document.createElement('option');
            opt.value = id;
            opt.textContent = gangLabel(id);
            gangSel.appendChild(opt);
        });

        bossSel.value = bossVal;
        gangSel.value = gangVal;
    }

    // Events
    btnAddGrade.addEventListener('click', function () {
        addGradeRow({ level: 0, name: '', payment: 0, isboss: false });
    });

    editorForm.addEventListener('submit', function (e) {
        e.preventDefault();
        const rawName = (editName.value || '').trim();
        if (!rawName) {
            showToast('Name is required', 'error');
            return;
        }
        const id = normalizeId(rawName);
        if (!id) {
            showToast('Invalid name', 'error');
            return;
        }

        const payload = {
            name: id,
            label: (editLabel.value || '').trim(),
            grades: collectGrades(),
        };

        if (currentTab === 'jobs') {
            payload.defaultDuty = !!editDefaultDuty.checked;
            payload.offDutyPay = !!editOffDutyPay.checked;
            payload.type = (editType.value || 'none').trim();
        }

        const endpoint = currentTab === 'jobs' ? 'saveJob' : 'saveGang';
        nuiFetch(endpoint, payload).then(function (res) {
            if (res && res.success) {
                showToast(res.message || 'Saved');
            } else {
                showToast((res && res.message) || 'Error', 'error');
            }
        }).catch(function () {
            showToast('Request failed', 'error');
        });
    });

    btnDelete.addEventListener('click', function () {
        const id = editId.value;
        if (!id) return;
        const endpoint = currentTab === 'jobs' ? 'deleteJob' : 'deleteGang';
        nuiFetch(endpoint, { name: id }).then(function (res) {
            if (res && res.success) {
                showToast(res.message || 'Deleted');
                selectedId = null;
                editorPlaceholder.classList.remove('hidden');
                editorForm.classList.add('hidden');
            } else {
                showToast((res && res.message) || 'Error', 'error');
            }
        }).catch(function () {
            showToast('Request failed', 'error');
        });
    });

    btnClose.addEventListener('click', function () {
        nuiFetch('close').then(function () {});
    });

    window.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && app && !app.classList.contains('hidden')) {
            nuiFetch('close').then(function () {});
        }
    });

    btnBossMenu.addEventListener('click', function () {
        nuiFetch('openBossMenu').then(function () {});
    });

    btnGangMenu.addEventListener('click', function () {
        nuiFetch('openGangMenu').then(function () {});
    });

    btnNew.addEventListener('click', function () {
        selectItem(null, true);
    });

    document.querySelectorAll('.tab').forEach(function (tab) {
        tab.addEventListener('click', function () {
            currentTab = tab.dataset.tab;
            document.querySelectorAll('.tab').forEach(function (t) {
                t.classList.remove('active');
            });
            tab.classList.add('active');

            if (currentTab === 'locations') {
                listTitle.textContent = 'Locations';
                editorPlaceholder.classList.add('hidden');
                editorForm.classList.add('hidden');
                locationsPanel.classList.remove('hidden');
            } else {
                locationsPanel.classList.add('hidden');
                editorPlaceholder.classList.remove('hidden');
                editorForm.classList.add('hidden');
                listTitle.textContent = currentTab === 'jobs' ? 'Jobs' : 'Gangs';
            }

            selectedId = null;
            renderList();
        });
    });

    btnAddBossLocation.addEventListener('click', function () {
        const jobId = selectBossJob.value;
        if (!jobId) {
            showToast('Select a job first', 'error');
            return;
        }
        const jobName = jobLabel(jobId);
        nuiFetch('addBossLocationAtPosition', {
            name: jobName,
            job: jobId,
            showblip: false,
        }).then(function (res) {
            if (res && res.success) {
                showToast('Boss location added for ' + jobName);
            } else {
                showToast('Failed to add', 'error');
            }
        }).catch(function () {
            showToast('Failed to add', 'error');
        });
    });

    btnAddGangLocation.addEventListener('click', function () {
        const gangId = selectGangGang.value;
        if (!gangId) {
            showToast('Select a gang first', 'error');
            return;
        }
        const gangName = gangLabel(gangId);
        nuiFetch('addGangLocationAtPosition', {
            name: gangName,
            gang: gangId,
            blipname: gangName,
            showblip: true,
            blipforall: false,
        }).then(function (res) {
            if (res && res.success) {
                showToast('Gang location added for ' + gangName);
            } else {
                showToast('Failed to add', 'error');
            }
        }).catch(function () {
            showToast('Failed to add', 'error');
        });
    });

    window.addEventListener('message', function (event) {
        const msg = event.data || {};
        if (msg.action === 'open') {
            app.classList.remove('hidden');
            if (msg.showBossMenu === false) {
                btnBossMenu.classList.add('hidden');
            } else {
                btnBossMenu.classList.remove('hidden');
            }
            if (msg.showGangMenu === false) {
                btnGangMenu.classList.add('hidden');
            } else {
                btnGangMenu.classList.remove('hidden');
            }
        } else if (msg.action === 'close') {
            app.classList.add('hidden');
        } else if (msg.action === 'setData' && msg.data) {
            data = msg.data || {};
            if (!data.bossLocations) data.bossLocations = [];
            if (!data.gangLocations) data.gangLocations = [];
            renderList();
            renderLocationsLists();
            if (selectedId) {
                const items = getCurrentItems();
                if (!items[selectedId]) {
                    selectedId = null;
                    editorPlaceholder.classList.remove('hidden');
                    editorForm.classList.add('hidden');
                } else {
                    selectItem(selectedId, false);
                }
            }
        }
    });
})();

