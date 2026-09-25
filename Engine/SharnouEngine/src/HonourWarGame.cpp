#include "sharnou/HonourWarGame.h"
#include "sharnou/D3D11Renderer.h"
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <sstream>

using namespace DirectX;
using json=nlohmann::json;

namespace Sharnou {

static int TierForLevel(int level) {
    if(level>=200) return 5;
    if(level>=150) return 4;
    if(level>=50) return 3;
    if(level>=25) return 2;
    return 1;
}

bool HonourWarGame::Initialize() {
    const char* local=std::getenv("LOCALAPPDATA");
    const std::filesystem::path saveRoot=local ? std::filesystem::path(local)/"SharnouEngine"/"HonourWar" : ".";
    std::filesystem::create_directories(saveRoot);

    for(const auto& p: {std::filesystem::path("data"),std::filesystem::path("..")/"data",std::filesystem::path("..")/".." /"data",std::filesystem::path("..")/".." /".." /"data"}) {
        if(std::filesystem::exists(p/"honour_war_content_catalog.json")) { dataRoot_=std::filesystem::absolute(p).string(); break; }
    }
    if(dataRoot_.empty()) return false;

    skills_={{{"Ember Slash",0.95f,18},{"Shield Bash",0.99f,21},{"Guard Break",1.03f,24},{"Brave Charge",1.07f,27},
              {"Iron Resolve",1.11f,30},{"War Cry",1.15f,33},{"Cleave",1.19f,36},{"Ember Guard",1.23f,39}}};

    if(!LoadCanonicalData()) return false;
    LoadGame();

    monsters_.clear();
    for(int i=0;i<32;i++) {
        Monster m;
        m.id="RUNTIME_"+std::to_string(i+1);
        m.name=i%4==0 ? "Dragon" : (i%2 ? "Goblin" : "Poring");
        m.level=10+i;
        m.maxHp=m.hp=80+m.level*20;
        m.position=XMFLOAT3(-12.0f+(i%8)*3.5f,0.8f,4.0f+(i/8)*3.5f);
        monsters_.push_back(m);
    }
    return RunSelfTest();
}

bool HonourWarGame::LoadCanonicalData() {
    try {
        std::ifstream in(std::filesystem::path(dataRoot_)/"honour_war_content_catalog.json");
        in>>catalog_;
        const auto counts=catalog_.at("counts");
        const bool ok=counts.at("characters").get<int>()==70 &&
                      counts.at("monsters").get<int>()==256 &&
                      counts.at("maps").get<int>()==24 &&
                      counts.at("equipment").get<int>()==300 &&
                      counts.at("items").get<int>()==76 &&
                      counts.at("cards").get<int>()==300 &&
                      counts.at("pets").get<int>()==20 &&
                      counts.at("pet_skills").get<int>()==120 &&
                      counts.at("pet_equipment").get<int>()==100;
        return ok;
    } catch(...) { return false; }
}

void HonourWarGame::LoadGame() {
    const char* local=std::getenv("LOCALAPPDATA");
    const auto save=local ? std::filesystem::path(local)/"SharnouEngine"/"HonourWar"/"player_save.json" : std::filesystem::path("player_save.json");
    std::ifstream in(save);
    if(!in.good()) return;
    try {
        json j; in>>j;
        player_.username=j.value("username","player");
        player_.characterName=j.value("characterName","Adventurer");
        player_.level=std::clamp(j.value("level",1),1,250);
        player_.ageDays=std::max(0,j.value("ageDays",0));
        player_.onlineSeconds=std::max(0.0,j.value("onlineSeconds",0.0));
        player_.position=XMFLOAT3(j.value("x",0.0f),1.0f,j.value("z",0.0f));
    } catch(...) {}
}

void HonourWarGame::SaveGame() {
    const char* local=std::getenv("LOCALAPPDATA");
    const auto save=local ? std::filesystem::path(local)/"SharnouEngine"/"HonourWar"/"player_save.json" : std::filesystem::path("player_save.json");
    try {
        json j={{"username",player_.username},{"characterName",player_.characterName},{"level",player_.level},
                {"ageDays",player_.ageDays},{"onlineSeconds",player_.onlineSeconds},{"x",player_.position.x},{"z",player_.position.z}};
        std::ofstream out(save); out<<j.dump(2);
    } catch(...) {}
}

void HonourWarGame::RecalculateAge() {
    player_.ageDays=static_cast<int>(player_.onlineSeconds/86400.0);
}

void HonourWarGame::Update(float dt) {
    player_.onlineSeconds+=dt;
    RecalculateAge();
    MoveTowardTarget(dt);
    SaveGame();
}

void HonourWarGame::MoveTowardTarget(float dt) {
    if(!player_.moving) return;
    XMVECTOR p=XMLoadFloat3(&player_.position);
    XMVECTOR t=XMLoadFloat3(&player_.moveTarget);
    XMVECTOR d=XMVectorSetY(t-p,0);
    const float len=XMVectorGetX(XMVector3Length(d));
    if(len<0.08f){player_.moving=false;return;}
    const XMVECTOR step=XMVector3Normalize(d)*(6.0f*dt);
    XMStoreFloat3(&player_.position,p+step);
}

void HonourWarGame::OnLeftClick(int x,int y) {
    const float sx=(float(x)/1600.0f)*2.0f-1.0f;
    const float sy=1.0f-(float(y)/900.0f)*2.0f;
    player_.moveTarget=XMFLOAT3(player_.position.x+sx*12.0f,1.0f,player_.position.z+sy*12.0f);
    player_.moving=true;
    selectedMonster_=-1;

    float best=2.2f;
    for(int i=0;i<(int)monsters_.size();++i) {
        if(!monsters_[i].alive) continue;
        const float dx=monsters_[i].position.x-player_.moveTarget.x;
        const float dz=monsters_[i].position.z-player_.moveTarget.z;
        const float d=std::sqrt(dx*dx+dz*dz);
        if(d<best){best=d;selectedMonster_=i;}
    }
}

void HonourWarGame::OnRightDrag(float dx,float dy) {
    cameraYaw_+=dx*0.25f;
    cameraPitch_=std::clamp(cameraPitch_-dy*0.12f,25.0f,70.0f);
}

void HonourWarGame::OnMouseWheel(float delta) {
    cameraDistance_=std::clamp(cameraDistance_-delta*0.002f,7.0f,24.0f);
}

void HonourWarGame::OnKeyDown(unsigned int key) {
    if(key>='1' && key<='8') ActivateSkill(int(key-'1'));
}

void HonourWarGame::ActivateSkill(int slot) {
    if(slot<0||slot>=8||selectedMonster_<0||selectedMonster_>=int(monsters_.size())) return;
    auto& m=monsters_[selectedMonster_];
    if(!m.alive||player_.sp<skills_[slot].resourceCost) return;
    player_.sp-=skills_[slot].resourceCost;
    const float scale=1.0f+float(player_.skillLevels[slot]-1)*0.08f;
    const int damage=std::max(1,int(35.0f*skills_[slot].powerRatio*scale));
    m.hp=std::max(0,m.hp-damage);
    if(m.hp==0) m.alive=false;
}

void HonourWarGame::SubmitCommand(const std::string& command) {
    std::istringstream ss(command);
    std::string verb,map,xy; ss>>verb>>map>>xy;
    if(verb=="@go"&&!map.empty()&&!xy.empty()) {
        const auto colon=xy.find(':');
        if(colon!=std::string::npos) {
            try {
                const float x=std::stof(xy.substr(0,colon)), z=std::stof(xy.substr(colon+1));
                player_.position=XMFLOAT3(x/10.0f,1.0f,z/10.0f);
                player_.moveTarget=player_.position; player_.moving=false;
            } catch(...) {}
        }
    }
}

bool HonourWarGame::RunSelfTest() {
    bool ok=LoadCanonicalData();
    for(int c=0;c<7;c++) {
        player_.classId=static_cast<HonourClass>(c);
        selectedMonster_=0;
        monsters_[0].alive=true; monsters_[0].hp=monsters_[0].maxHp;
        for(int s=0;s<8;s++) {
            player_.sp=player_.maxSp;
            const int hpBefore=monsters_[0].hp;
            ActivateSkill(s);
            if(monsters_[0].hp>=hpBefore) ok=false;
            monsters_[0].hp=monsters_[0].maxHp; monsters_[0].alive=true;
        }
    }
    return ok;
}

void HonourWarGame::Render(D3D11Renderer& renderer) {
    const XMFLOAT3 p=player_.position;
    const float yaw=XMConvertToRadians(cameraYaw_), pitch=XMConvertToRadians(cameraPitch_);
    XMVECTOR target=XMVectorSet(p.x,p.y+0.8f,p.z,1);
    XMVECTOR offset=XMVectorSet(0,0,cameraDistance_,0);
    XMMATRIX rot=XMMatrixRotationRollPitchYaw(pitch,yaw,0);
    XMVECTOR eye=target+XMVector3TransformCoord(offset,rot);
    XMMATRIX view=XMMatrixLookAtLH(eye,target,XMVectorSet(0,1,0,0));
    XMMATRIX projection=XMMatrixPerspectiveFovLH(XMConvertToRadians(60.0f),1600.0f/900.0f,0.1f,1000.0f);
    renderer.SetCamera(view,projection);

    renderer.RenderCube(XMMatrixScaling(18,0.12f,18)*XMMatrixTranslation(0,-0.12f,7),XMFLOAT4(0.07f,0.09f,0.12f,1));
    renderer.RenderCube(XMMatrixScaling(0.75f,1.0f,0.75f)*XMMatrixTranslation(p.x,p.y,p.z),XMFLOAT4(0.85f,0.72f,0.22f,1));

    for(size_t i=0;i<monsters_.size();++i) {
        const auto& m=monsters_[i];
        XMFLOAT4 color=(int(i)==selectedMonster_)?XMFLOAT4(1,0.35f,0.10f,1):XMFLOAT4(0.50f,0.22f,0.72f,1);
        if(!m.alive) color=XMFLOAT4(0.05f,0.05f,0.05f,1);
        renderer.RenderCube(XMMatrixScaling(0.72f,0.82f,0.72f)*XMMatrixTranslation(m.position.x,m.position.y,m.position.z),color);
    }
}

}
