from dataclasses import dataclass, fields
from typing import Optional

@dataclass
class SbatchOptions:
    account: Optional[str] = None
    nodes: Optional[int] = None
    job_name: Optional[str] = None
    ntasks_per_node: Optional[int] = None
    output: Optional[str] = None
    partition: Optional[str] = None
    exclusive: bool = False
    
    @property
    def header(self):
        option_names = [f.name for f in fields(self)]
        only_oname = ['exclusive']
        header_str = ''
        for oname in option_names:
            oval = getattr(self, oname)
            if oval:
                if oname in only_oname:
                    header_str += '\n#SBATCH --' + oname.replace('_','-')
                else:  
                    header_str += '\n#SBATCH --' + oname.replace('_','-') + '=' + str(oval) 

        return header_str
    

aux =  SbatchOptions(
    account ='my-account',
    nodes= 1,
    exclusive = "False"
)

print(aux.header)